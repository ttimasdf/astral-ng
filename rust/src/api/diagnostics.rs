use crate::diagnostics;
use crate::frb_generated::StreamSink;
use std::collections::HashMap;

#[derive(Clone, Debug)]
pub struct RustDiagnosticBatch {
    pub events: Vec<RustDiagnosticEvent>,
}

#[derive(Clone, Debug)]
pub struct RustDiagnosticEvent {
    pub timestamp_millis: i64,
    pub source_sequence: u64,
    pub level: String,
    pub module: String,
    pub raw_target: String,
    pub source_file: Option<String>,
    pub source_line: Option<u32>,
    pub source_function: Option<String>,
    pub event_code: Option<String>,
    pub message: String,
    pub fields: HashMap<String, String>,
    pub console_already_reported: bool,
}

pub fn initialize_rust_diagnostics(filter: String) -> Result<(), String> {
    diagnostics::init(&filter)
}

pub fn set_rust_diagnostic_filter(filter: String) -> Result<(), String> {
    diagnostics::set_filter(&filter)
}

pub fn create_rust_diagnostic_stream(sink: StreamSink<RustDiagnosticBatch>) {
    diagnostics::set_stream(sink);
}
