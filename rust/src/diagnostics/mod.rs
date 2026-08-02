use crate::api::diagnostics::{RustDiagnosticBatch, RustDiagnosticEvent};
use crate::frb_generated::StreamSink;
use chrono::Utc;
use std::collections::{BTreeMap, HashMap};
#[cfg(target_os = "android")]
use std::ffi::CString;
use std::sync::atomic::{AtomicU64, AtomicUsize, Ordering};
use std::sync::{mpsc, Mutex, OnceLock};
use std::time::{Duration, Instant};
use tracing::field::{Field, Visit};
use tracing::span::{Attributes, Id};
use tracing::{Event, Metadata, Subscriber};
use tracing_subscriber::filter::EnvFilter;
use tracing_subscriber::layer::{Context, SubscriberExt};
use tracing_subscriber::registry::LookupSpan;
use tracing_subscriber::reload;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::{Layer, Registry};

const BRIDGE_CAPACITY: usize = 1_000;
const MAX_FIELD_LENGTH: usize = 1_024;
const MAX_MESSAGE_LENGTH: usize = 4_096;

type FilterHandle = reload::Handle<EnvFilter, Registry>;

static FILTER_HANDLE: OnceLock<FilterHandle> = OnceLock::new();
static BRIDGE_SINK: OnceLock<Mutex<Option<StreamSink<RustDiagnosticBatch>>>> = OnceLock::new();
static BRIDGE_SENDER: OnceLock<mpsc::SyncSender<RustDiagnosticEvent>> = OnceLock::new();
static SOURCE_SEQUENCE: AtomicU64 = AtomicU64::new(0);
static DROPPED_RECORDS: AtomicUsize = AtomicUsize::new(0);
static INITIALIZED: OnceLock<()> = OnceLock::new();

pub fn init(filter: &str) -> Result<(), String> {
    if INITIALIZED.get().is_some() {
        return set_filter(filter);
    }

    init_bridge_worker();
    let env_filter = EnvFilter::try_new(filter)
        .map_err(|error| format!("invalid Rust diagnostic filter: {error}"))?;
    let (filter_layer, filter_handle) = reload::Layer::new(env_filter);
    Registry::default()
        .with(filter_layer)
        .with(AstralDiagnosticLayer)
        .try_init()
        .map_err(|error| format!("failed to install Rust diagnostic subscriber: {error}"))?;
    FILTER_HANDLE
        .set(filter_handle)
        .map_err(|_| "Rust diagnostic filter was initialized twice".to_string())?;
    install_panic_hook();
    let _ = INITIALIZED.set(());
    tracing::info!(
        target: "astral.bootstrap",
        event_code = "rust.diagnostics.ready",
        filter,
        "Rust diagnostics initialized"
    );
    Ok(())
}

pub fn set_filter(filter: &str) -> Result<(), String> {
    let parsed = EnvFilter::try_new(filter)
        .map_err(|error| format!("invalid Rust diagnostic filter: {error}"))?;
    FILTER_HANDLE
        .get()
        .ok_or_else(|| "Rust diagnostics are not initialized".to_string())?
        .reload(parsed)
        .map_err(|error| format!("failed to reload Rust diagnostic filter: {error}"))
}

pub fn set_stream(sink: StreamSink<RustDiagnosticBatch>) {
    let sink_slot = BRIDGE_SINK.get_or_init(|| Mutex::new(None));
    if let Ok(mut current) = sink_slot.lock() {
        *current = Some(sink);
    } else {
        write_emergency(
            "ERR",
            "logging",
            "rust.bridge.lock_failed",
            "Rust diagnostic bridge lock is poisoned",
        );
    }
}

fn init_bridge_worker() {
    BRIDGE_SINK.get_or_init(|| Mutex::new(None));
    BRIDGE_SENDER.get_or_init(|| {
        let (sender, receiver) = mpsc::sync_channel(BRIDGE_CAPACITY);
        let worker = std::thread::Builder::new()
            .name("astral-diagnostics".to_string())
            .spawn(move || {
                while let Ok(first) = receiver.recv() {
                    let mut events = Vec::with_capacity(50);
                    events.push(first);
                    let deadline = Instant::now() + Duration::from_millis(50);
                    while events.len() < 50 {
                        let Some(remaining) = deadline.checked_duration_since(Instant::now())
                        else {
                            break;
                        };
                        match receiver.recv_timeout(remaining) {
                            Ok(event) => events.push(event),
                            Err(mpsc::RecvTimeoutError::Timeout) => break,
                            Err(mpsc::RecvTimeoutError::Disconnected) => break,
                        }
                    }
                    let Some(slot) = BRIDGE_SINK.get() else {
                        continue;
                    };
                    let Ok(mut sink) = slot.lock() else {
                        continue;
                    };
                    let Some(current) = sink.as_ref() else {
                        continue;
                    };
                    if current.add(RustDiagnosticBatch { events }).is_err() {
                        *sink = None;
                    }
                }
            });
        if let Err(error) = worker {
            write_emergency(
                "ERR",
                "logging",
                "rust.bridge.worker_failed",
                &format!("Failed to start Rust diagnostic bridge worker: {error}"),
            );
        }
        sender
    });
}

struct AstralDiagnosticLayer;

impl<S> Layer<S> for AstralDiagnosticLayer
where
    S: Subscriber + for<'lookup> LookupSpan<'lookup>,
{
    fn on_new_span(&self, attributes: &Attributes<'_>, id: &Id, ctx: Context<'_, S>) {
        let Some(span) = ctx.span(id) else {
            return;
        };
        let mut visitor = FieldVisitor::default();
        attributes.record(&mut visitor);
        span.extensions_mut().insert(SpanFields(visitor.fields));
    }

    fn on_event(&self, event: &Event<'_>, ctx: Context<'_, S>) {
        let diagnostic = normalize_event(event, &ctx);
        write_native(&diagnostic);
        enqueue_bridge(diagnostic);
    }
}

fn normalize_event<S>(event: &Event<'_>, ctx: &Context<'_, S>) -> RustDiagnosticEvent
where
    S: Subscriber + for<'lookup> LookupSpan<'lookup>,
{
    let metadata = event.metadata();
    let mut fields = BTreeMap::new();
    if let Some(scope) = ctx.event_scope(event) {
        for span in scope.from_root() {
            if let Some(span_fields) = span.extensions().get::<SpanFields>() {
                fields.extend(span_fields.0.clone());
            }
        }
    }
    let mut visitor = FieldVisitor { fields };
    event.record(&mut visitor);
    let mut fields = visitor.fields;
    let message = truncate(
        fields
            .remove("message")
            .unwrap_or_else(|| metadata.name().to_string()),
        MAX_MESSAGE_LENGTH,
    );
    let event_code = fields
        .remove("event_code")
        .unwrap_or_else(|| default_event_code(metadata));
    let target = metadata.target().to_string();
    RustDiagnosticEvent {
        timestamp_millis: Utc::now().timestamp_millis(),
        source_sequence: SOURCE_SEQUENCE.fetch_add(1, Ordering::Relaxed),
        level: metadata.level().as_str().to_ascii_lowercase(),
        module: map_target(metadata.target()),
        raw_target: target,
        event_code: truncate(event_code, 128),
        message,
        fields: fields.into_iter().collect(),
        console_already_reported: true,
    }
}

fn enqueue_bridge(event: RustDiagnosticEvent) {
    let dropped = DROPPED_RECORDS.swap(0, Ordering::Relaxed);
    if dropped > 0 {
        let mut fields = HashMap::new();
        fields.insert("count".to_string(), dropped.to_string());
        let summary = RustDiagnosticEvent {
            timestamp_millis: Utc::now().timestamp_millis(),
            source_sequence: SOURCE_SEQUENCE.fetch_add(1, Ordering::Relaxed),
            level: "warning".to_string(),
            module: "astral.logging".to_string(),
            raw_target: "astral.diagnostics".to_string(),
            event_code: "logging.records.suppressed".to_string(),
            message: "Rust diagnostic bridge suppressed records".to_string(),
            fields,
            console_already_reported: true,
        };
        write_native(&summary);
        if !try_send(summary) {
            DROPPED_RECORDS.fetch_add(dropped, Ordering::Relaxed);
        }
    }
    if !try_send(event) {
        DROPPED_RECORDS.fetch_add(1, Ordering::Relaxed);
    }
}

fn try_send(event: RustDiagnosticEvent) -> bool {
    BRIDGE_SENDER
        .get()
        .is_some_and(|sender| sender.try_send(event).is_ok())
}

#[derive(Clone)]
struct SpanFields(BTreeMap<String, String>);

#[derive(Default)]
struct FieldVisitor {
    fields: BTreeMap<String, String>,
}

impl Visit for FieldVisitor {
    fn record_bool(&mut self, field: &Field, value: bool) {
        self.insert(field, value.to_string());
    }

    fn record_i64(&mut self, field: &Field, value: i64) {
        self.insert(field, value.to_string());
    }

    fn record_u64(&mut self, field: &Field, value: u64) {
        self.insert(field, value.to_string());
    }

    fn record_f64(&mut self, field: &Field, value: f64) {
        self.insert(field, value.to_string());
    }

    fn record_str(&mut self, field: &Field, value: &str) {
        self.insert(field, value.to_string());
    }

    fn record_debug(&mut self, field: &Field, value: &dyn std::fmt::Debug) {
        self.insert(field, format!("{value:?}"));
    }
}

impl FieldVisitor {
    fn insert(&mut self, field: &Field, value: String) {
        let key = field.name().to_string();
        let safe_value = if is_sensitive_key(&key) {
            "<redacted>".to_string()
        } else {
            truncate(value, MAX_FIELD_LENGTH)
        };
        self.fields.insert(key, safe_value);
    }
}

fn is_sensitive_key(key: &str) -> bool {
    let normalized = key.to_ascii_lowercase().replace('-', "_");
    [
        "password",
        "token",
        "authorization",
        "cookie",
        "private_key",
        "secret",
        "credential",
    ]
    .iter()
    .any(|needle| normalized.contains(needle))
}

fn truncate(mut value: String, max: usize) -> String {
    if value.len() <= max {
        return value;
    }
    let mut boundary = max;
    while boundary > 0 && !value.is_char_boundary(boundary) {
        boundary -= 1;
    }
    value.truncate(boundary);
    value.push_str("…<truncated>");
    value
}

fn default_event_code(metadata: &Metadata<'_>) -> String {
    format!(
        "rust.{}",
        metadata.name().replace(' ', "-").to_ascii_lowercase()
    )
}

pub fn map_target(target: &str) -> String {
    if target.starts_with("astral.") {
        return target.to_string();
    }
    if target.starts_with("CORE::INSTANCE::CONNECTION") {
        return "astral.easytier.connection".to_string();
    }
    if target.starts_with("CORE::INSTANCE") {
        return "astral.easytier.instance".to_string();
    }
    if target.starts_with("CORE") {
        return "astral.easytier".to_string();
    }
    if target.contains("::tunnel::") {
        return format!(
            "astral.easytier.tunnel.{}",
            target
                .split("::tunnel::")
                .nth(1)
                .unwrap_or("unknown")
                .replace("::", ".")
        );
    }
    if target.starts_with("easytier") {
        return format!("astral.{}", target.replace("::", "."));
    }
    if target.starts_with("rust_lib_astral") {
        return format!("astral.rust.{}", target.replace("::", "."));
    }
    "astral.easytier".to_string()
}

fn format_native(event: &RustDiagnosticEvent) -> String {
    let module = event
        .module
        .strip_prefix("astral.")
        .unwrap_or(&event.module);
    let mut field_entries = event.fields.iter().collect::<Vec<_>>();
    field_entries.sort_by_key(|(key, _)| *key);
    let fields = field_entries
        .into_iter()
        .map(|(key, value)| format!("{key}={value}"))
        .collect::<Vec<_>>()
        .join(" ");
    let suffix = if fields.is_empty() {
        String::new()
    } else {
        format!(" | {fields}")
    };
    format!(
        "{} {:<18} {:<24} {}{}",
        level_token(&event.level),
        module,
        event.event_code,
        event.message,
        suffix
    )
}

fn level_token(level: &str) -> &'static str {
    match level {
        "trace" => "TRC",
        "debug" => "DBG",
        "info" => "INF",
        "warn" | "warning" => "WRN",
        "error" => "ERR",
        _ => "INF",
    }
}

fn write_native(event: &RustDiagnosticEvent) {
    write_native_line(android_priority(&event.level), &format_native(event));
}

fn write_emergency(level: &str, module: &str, code: &str, message: &str) {
    write_native_line(
        android_priority(level),
        &format!("{level} {module:<18} {code:<24} {message}"),
    );
}

#[cfg(not(target_os = "android"))]
fn write_native_line(_priority: i32, message: &str) {
    eprintln!("{message}");
}

#[cfg(target_os = "android")]
fn write_native_line(priority: i32, message: &str) {
    const TAG: &[u8] = b"AstralRust\0";
    let safe = message.replace('\0', "�");
    if let Ok(message) = CString::new(safe) {
        unsafe {
            __android_log_write(priority, TAG.as_ptr().cast(), message.as_ptr());
        }
    }
}

#[cfg(target_os = "android")]
#[link(name = "log")]
unsafe extern "C" {
    fn __android_log_write(
        priority: i32,
        tag: *const std::ffi::c_char,
        text: *const std::ffi::c_char,
    ) -> i32;
}

fn android_priority(level: &str) -> i32 {
    match level {
        "trace" => 2,
        "debug" => 3,
        "info" => 4,
        "warn" | "warning" => 5,
        "error" | "fatal" | "ERR" | "FTL" => 6,
        _ => 4,
    }
}

fn install_panic_hook() {
    let previous = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        write_emergency("FTL", "rust", "rust.panic", &info.to_string());
        previous(info);
    }));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_stable_easytier_targets() {
        assert_eq!(map_target("CORE::INSTANCE"), "astral.easytier.instance");
        assert_eq!(
            map_target("CORE::INSTANCE::CONNECTION"),
            "astral.easytier.connection"
        );
        assert_eq!(
            map_target("easytier::tunnel::udp"),
            "astral.easytier.tunnel.udp"
        );
    }

    #[test]
    fn redacts_sensitive_fields() {
        let mut visitor = FieldVisitor::default();
        let field_set = tracing::field::FieldSet::new(
            &["room_password"],
            tracing::callsite::Identifier(&TEST_CALLSITE),
        );
        let field = field_set.field("room_password").unwrap();
        visitor.record_str(&field, "secret");
        assert_eq!(visitor.fields["room_password"], "<redacted>");
    }

    struct TestCallsite;
    static TEST_CALLSITE: TestCallsite = TestCallsite;

    impl tracing::callsite::Callsite for TestCallsite {
        fn set_interest(&self, _interest: tracing::subscriber::Interest) {}

        fn metadata(&self) -> &Metadata<'_> {
            panic!("metadata is not used by this test")
        }
    }
}
