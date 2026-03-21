#[derive(Debug)]
pub enum LedgerError {
    Disconnected,
    Timeout,
    Io(String),
    Framing(String),
}

impl std::fmt::Display for LedgerError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            LedgerError::Disconnected => write!(f, "Device disconnected"),
            LedgerError::Timeout => write!(f, "Device timeout"),
            LedgerError::Io(msg) => write!(f, "I/O error: {}", msg),
            LedgerError::Framing(msg) => write!(f, "Framing error: {}", msg),
        }
    }
}
