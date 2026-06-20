use crate::utils::errors::ServiceError;
use std::sync::{Arc, LazyLock};
use zilpay::background::{bg_storage::StorageManagement, Background};
use zilpay::tokio::sync::{Mutex, RwLock};
use zilpay::tokio::task::JoinHandle;

pub struct ServiceBackground {
    pub block_handle: Mutex<Option<JoinHandle<()>>>,
    pub history_handle: Mutex<Option<JoinHandle<()>>>,
    pub core: RwLock<Arc<Background>>,
}

pub static BACKGROUND_SERVICE: LazyLock<RwLock<Option<ServiceBackground>>> =
    LazyLock::new(|| RwLock::new(None));

impl ServiceBackground {
    pub fn from_path(path: &str) -> Result<Self, ServiceError> {
        let core = Background::from_storage_path(path).map_err(ServiceError::BackgroundError)?;

        Ok(Self {
            core: RwLock::new(Arc::new(core)),
            block_handle: Mutex::new(None),
            history_handle: Mutex::new(None),
        })
    }
}
