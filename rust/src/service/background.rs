use arc_swap::ArcSwapOption;
use crate::utils::errors::ServiceError;
use std::sync::{Arc, LazyLock};
use zilpay::background::{bg_storage::StorageManagement, Background};
use zilpay::tokio::sync::{Mutex, RwLock};
use zilpay::tokio::task::JoinHandle;

pub struct ServiceBackground {
    /// Serializes COW mutations on `core` so two concurrent `mutate_core` calls
    /// can't both load the same snapshot and drop the other's write.
    pub mutation_mutex: Mutex<()>,
    pub block_handle: Mutex<Option<JoinHandle<()>>>,
    pub history_handle: Mutex<Option<JoinHandle<()>>>,
    /// The active `Background` snapshot. Readers use [`ArcSwapOption::load_full`]
    /// (lock-free atomic load); mutations clone, modify, then [`ArcSwapOption::store`].
    pub core: ArcSwapOption<Background>,
}

pub static BACKGROUND_SERVICE: LazyLock<RwLock<Option<ServiceBackground>>> =
    LazyLock::new(|| RwLock::new(None));

impl ServiceBackground {
    pub fn from_path(path: &str) -> Result<Self, ServiceError> {
        let core = Background::from_storage_path(path).map_err(ServiceError::BackgroundError)?;

        Ok(Self {
            core: ArcSwapOption::new(Some(Arc::new(core))),
            mutation_mutex: Mutex::new(()),
            block_handle: Mutex::new(None),
            history_handle: Mutex::new(None),
        })
    }
}
