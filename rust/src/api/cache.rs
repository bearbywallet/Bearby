use std::path::PathBuf;

pub use zilpay::background::bg_book::AddressBookManagement;
pub use zilpay::background::book::AddressBookEntry;
pub use zilpay::cache::Cache;
pub use zilpay::settings::{
    notifications::NotificationState,
    theme::{Appearances, Theme},
};

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_image_name(dir: String, url: String) -> Result<String, String> {
    let cache = Cache::new(PathBuf::from(dir)).map_err(|e| e.to_string())?;
    let image_name = cache
        .get_image_name(&url)
        .await
        .map_err(|e| e.to_string())?;

    Ok(image_name)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_image_bytes(dir: String, url: String) -> Result<(Vec<u8>, String), String> {
    let cache = Cache::new(PathBuf::from(dir)).map_err(|e| e.to_string())?;
    let image_bytes = cache
        .get_image_bytes(&url)
        .await
        .map_err(|e| e.to_string())?;

    Ok(image_bytes)
}
