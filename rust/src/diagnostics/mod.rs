use crate::api::diagnostics::{RustDiagnosticBatch, RustDiagnosticEvent};
use crate::frb_generated::StreamSink;
use chrono::Utc;
use std::collections::{BTreeMap, HashMap, VecDeque};
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
static BRIDGE_STATE: OnceLock<Mutex<BridgeState>> = OnceLock::new();
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
    let bridge = BRIDGE_STATE.get_or_init(|| Mutex::new(BridgeState::default()));
    let Ok(mut state) = bridge.lock() else {
        write_emergency(
            "ERR",
            "logging",
            "rust.bridge.lock_failed",
            "Rust diagnostic bridge lock is poisoned",
        );
        return;
    };
    state.sink = Some(sink);
    while !state.pending.is_empty() {
        let mut events = Vec::with_capacity(50);
        while events.len() < 50 {
            let Some(event) = state.pending.pop_front() else {
                break;
            };
            events.push(event);
        }
        let failed = state.sink.as_ref().is_none_or(|current| {
            current
                .add(RustDiagnosticBatch {
                    events: events.clone(),
                })
                .is_err()
        });
        if failed {
            state.sink = None;
            for event in events.into_iter().rev() {
                state.pending.push_front(event);
            }
            break;
        }
    }
}

fn init_bridge_worker() {
    BRIDGE_STATE.get_or_init(|| Mutex::new(BridgeState::default()));
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
                    let Some(bridge) = BRIDGE_STATE.get() else {
                        continue;
                    };
                    let Ok(mut state) = bridge.lock() else {
                        continue;
                    };
                    let delivered = state.sink.as_ref().is_some_and(|current| {
                        current
                            .add(RustDiagnosticBatch {
                                events: events.clone(),
                            })
                            .is_ok()
                    });
                    if !delivered {
                        state.sink = None;
                        state.buffer(events);
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

#[derive(Default)]
struct BridgeState {
    sink: Option<StreamSink<RustDiagnosticBatch>>,
    pending: VecDeque<RustDiagnosticEvent>,
}

impl BridgeState {
    fn buffer(&mut self, events: Vec<RustDiagnosticEvent>) {
        for event in events {
            if self.pending.len() >= BRIDGE_CAPACITY {
                self.pending.pop_front();
                DROPPED_RECORDS.fetch_add(1, Ordering::Relaxed);
            }
            self.pending.push_back(event);
        }
    }
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
            .unwrap_or_else(|| "Rust event".to_string()),
        MAX_MESSAGE_LENGTH,
    );
    let event_code = fields
        .remove("event_code")
        .filter(|value| !value.trim().is_empty())
        .map(|value| truncate(value, 128));
    let target = metadata.target().to_string();
    RustDiagnosticEvent {
        timestamp_millis: Utc::now().timestamp_millis(),
        source_sequence: SOURCE_SEQUENCE.fetch_add(1, Ordering::Relaxed),
        level: metadata.level().as_str().to_ascii_lowercase(),
        module: map_target(metadata.target()),
        raw_target: target,
        source_file: compact_rust_source_file(metadata.target(), metadata.file()),
        source_line: metadata.line(),
        source_function: metadata.module_path().map(str::to_string),
        event_code,
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
            source_file: None,
            source_line: None,
            source_function: Some("astral.diagnostics".to_string()),
            event_code: Some("logging.records.suppressed".to_string()),
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

fn compact_rust_source_file(target: &str, file: Option<&str>) -> Option<String> {
    let normalized = file?.replace('\\', "/");
    let (crate_directory, relative) =
        if let Some((prefix, relative)) = normalized.rsplit_once("/src/") {
            (prefix.rsplit('/').next(), relative)
        } else if let Some(relative) = normalized.strip_prefix("src/") {
            (None, relative)
        } else {
            (None, normalized.rsplit('/').next().unwrap_or("unknown"))
        };
    let crate_label = compact_crate_label(target, crate_directory);
    Some(format!("{crate_label}/{relative}"))
}

fn compact_crate_label<'a>(target: &str, crate_directory: Option<&'a str>) -> &'a str {
    match crate_directory {
        Some("rust") => "astral",
        Some(directory) => directory,
        None if target.starts_with("rust_lib_astral") || target.starts_with("astral") => "astral",
        None if target.starts_with("easytier") || target.starts_with("CORE") => "easytier",
        None => "rust",
    }
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
        event.event_code.as_deref().unwrap_or("-"),
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
    fn compacts_rust_event_source_paths() {
        assert_eq!(
            compact_rust_source_file(
                "CORE::INSTANCE::CONNECTION",
                Some(
                    "/home/u/.cargo/git/checkouts/easytier-af9fb4bbe1f7758c/8428a89/easytier/src/connector/manual.rs",
                ),
            ),
            Some("easytier/connector/manual.rs".to_string())
        );
        assert_eq!(
            compact_rust_source_file(
                "rust_lib_astral::api::simple",
                Some("rust\\src\\api\\simple.rs"),
            ),
            Some("astral/api/simple.rs".to_string())
        );
    }

    #[test]
    fn native_formatter_does_not_add_ansi_color() {
        let event = test_event(0);

        assert!(!format_native(&event).contains('\u{1b}'));
        assert!(format_native(&event).contains(" - "));
    }

    #[test]
    fn pre_attach_buffer_is_bounded_and_keeps_newest_records() {
        let mut state = BridgeState::default();
        state.buffer((0..=BRIDGE_CAPACITY).map(test_event).collect());

        assert_eq!(state.pending.len(), BRIDGE_CAPACITY);
        assert_eq!(state.pending.front().unwrap().source_sequence, 1);
        assert_eq!(
            state.pending.back().unwrap().source_sequence,
            BRIDGE_CAPACITY as u64
        );
    }

    fn test_event(sequence: usize) -> RustDiagnosticEvent {
        RustDiagnosticEvent {
            timestamp_millis: 0,
            source_sequence: sequence as u64,
            level: "info".to_string(),
            module: "astral.easytier".to_string(),
            raw_target: "CORE".to_string(),
            source_file: Some("easytier/connector/manual.rs".to_string()),
            source_line: Some(213),
            source_function: None,
            event_code: None,
            message: "Rust event".to_string(),
            fields: HashMap::new(),
            console_already_reported: true,
        }
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
