use arc_swap::ArcSwapOption;
use std::sync::LazyLock;
use zilpay::background::Background;
use zilpay::tokio::sync::{Mutex, RwLock};
use zilpay::tokio::task::JoinHandle;

/// The active `Background` snapshot. Lock-free atomic read via
/// [`ArcSwapOption::load_full`]; mutations clone → modify → [`ArcSwapOption::store`].
///
/// `Some`/`None` state is kept in lockstep with [`BACKGROUND_SERVICE`] by
/// `load_service`/`stop_service` under its outer write lock — never `store(None)`
/// from any other site.
pub static CORE: ArcSwapOption<Background> = ArcSwapOption::const_empty();

/// Serializes COW mutations so two concurrent `mutate_core` calls can't both
/// fork the same `CORE` snapshot and drop the other's write.
pub(crate) static MUTATION_MUTEX: LazyLock<Mutex<()>> = LazyLock::new(|| Mutex::new(()));

pub struct ServiceBackground {
    pub block_handle: Mutex<Option<JoinHandle<()>>>,
    pub history_handle: Mutex<Option<JoinHandle<()>>>,
}

impl Default for ServiceBackground {
    fn default() -> Self {
        Self::new()
    }
}

pub static BACKGROUND_SERVICE: LazyLock<RwLock<Option<ServiceBackground>>> =
    LazyLock::new(|| RwLock::new(None));

impl ServiceBackground {
    pub fn new() -> Self {
        Self {
            block_handle: Mutex::new(None),
            history_handle: Mutex::new(None),
        }
    }
}
