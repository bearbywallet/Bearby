pub use zilpay::background::connections::{Connection, ConnectionPermissions, DAppColors};

#[derive(Debug)]
pub struct ColorsInfo {
    pub primary: String,
    pub secondary: Option<String>,
    pub background: Option<String>,
    pub text: Option<String>,
}

impl From<DAppColors> for ColorsInfo {
    fn from(colors: DAppColors) -> Self {
        ColorsInfo {
            primary: colors.primary,
            secondary: colors.secondary,
            background: colors.background,
            text: colors.text,
        }
    }
}

impl From<ColorsInfo> for DAppColors {
    fn from(colors: ColorsInfo) -> Self {
        DAppColors {
            primary: colors.primary,
            secondary: colors.secondary,
            background: colors.background,
            text: colors.text,
        }
    }
}

#[derive(Debug)]
pub struct ConnectionInfo {
    // Base fields
    pub domain: String,
    pub wallet_indexes: Vec<usize>,
    pub favicon: Option<String>,
    pub title: String,
    pub description: Option<String>,
    // primary, secondary, background, text
    pub colors: Option<ColorsInfo>,

    pub last_connected: u64, // Unix timestamp

    // permissions
    pub can_read_accounts: bool,
    pub can_request_signatures: bool,
    pub can_suggest_tokens: bool,
    pub can_suggest_transactions: bool,
}

impl From<Connection> for ConnectionInfo {
    fn from(conn: Connection) -> Self {
        ConnectionInfo {
            colors: conn.colors.map(Into::into),
            domain: conn.domain,
            wallet_indexes: conn.wallet_indexes.into_iter().collect(),
            favicon: conn.favicon,
            title: conn.title,
            description: conn.description,
            last_connected: conn.last_connected,

            can_read_accounts: conn.permissions.can_read_accounts,
            can_request_signatures: conn.permissions.can_request_signatures,
            can_suggest_tokens: conn.permissions.can_suggest_tokens,
            can_suggest_transactions: conn.permissions.can_suggest_transactions,
        }
    }
}

impl From<ConnectionInfo> for Connection {
    fn from(conn_info: ConnectionInfo) -> Self {
        Connection {
            colors: conn_info.colors.map(Into::into),
            domain: conn_info.domain,
            wallet_indexes: conn_info.wallet_indexes.into_iter().collect(),
            favicon: conn_info.favicon,
            title: conn_info.title,
            description: conn_info.description,
            last_connected: conn_info.last_connected,
            permissions: ConnectionPermissions {
                can_read_accounts: conn_info.can_read_accounts,
                can_request_signatures: conn_info.can_request_signatures,
                can_suggest_tokens: conn_info.can_suggest_tokens,
                can_suggest_transactions: conn_info.can_suggest_transactions,
            },
        }
    }
}
