use crate::frb_generated::StreamSink;
use lazy_static::lazy_static;
use std::sync::Arc;
use tokio::sync::RwLock;
use zilpay::background::Background;

pub struct ServiceBackground {
    pub running: bool,
    pub message_sink: Option<StreamSink<String>>,
    pub core: Arc<Background>,
}

lazy_static! {
    pub static ref BACKGROUND_SERVICE: RwLock<Option<ServiceBackground>> = RwLock::new(None);
}

impl ServiceBackground {
    pub fn from_path(path: &str) -> Result<Self, String> {
        let core = Background::from_storage_path(path).map_err(|e| e.to_string())?;

        Ok(Self {
            core: Arc::new(core),
            running: true,
            message_sink: None,
        })
    }

    pub fn stop(&mut self) {
        self.running = false;
    }

    pub fn get_wallet_mut(
        &mut self,
        wallet_index: usize,
    ) -> Result<&mut zilpay::wallet::Wallet, String> {
        Arc::get_mut(&mut self.core)
            .ok_or("Cannot get mutable reference to core")?
            .wallets
            .get_mut(wallet_index)
            .ok_or("Fail to get mutable link to wallet".to_string())
    }
}
