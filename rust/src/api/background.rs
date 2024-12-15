use super::{notification::BackgroundNotificationState, wallet::WalletInfo};
use std::collections::HashMap;

#[derive(Debug)]
pub struct BackgroundState {
    pub wallets: Vec<WalletInfo>,
    pub notifications_wallet_states: HashMap<usize, BackgroundNotificationState>,
    pub notifications_global_enabled: bool,
    pub locale: String,
    pub appearances: u8,
}
