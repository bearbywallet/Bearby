use crate::utils::errors::ServiceError;
use lazy_static::lazy_static;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio::task::JoinHandle;
use zilpay::background::{bg_storage::StorageManagement, Background};

pub struct ServiceBackground {
    pub running: bool,
    pub block_handle: Option<JoinHandle<()>>,
    pub history_handle: Option<JoinHandle<()>>,
    pub core: Arc<Background>,
}

lazy_static! {
    pub static ref BACKGROUND_SERVICE: RwLock<Option<ServiceBackground>> = RwLock::new(None);
}

impl ServiceBackground {
    pub fn from_path(path: &str) -> Result<Self, ServiceError> {
        let core = Background::from_storage_path(path).map_err(ServiceError::BackgroundError)?;

        Ok(Self {
            core: Arc::new(core),
            running: true,
            block_handle: None,
            history_handle: None,
        })
    }

    pub fn stop(&mut self) {
        self.running = false;
    }

    pub fn get_wallet_mut(
        &mut self,
        wallet_index: usize,
    ) -> Result<&mut zilpay::wallet::Wallet, ServiceError> {
        Arc::get_mut(&mut self.core)
            .ok_or(ServiceError::CoreAccess)?
            .wallets
            .get_mut(wallet_index)
            .ok_or(ServiceError::WalletAccess(wallet_index))
    }
}
