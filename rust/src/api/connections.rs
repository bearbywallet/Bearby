use crate::{
    models::connection::ConnectionInfo,
    utils::{
        errors::ServiceError,
        utils::{with_service, with_service_mut},
    },
};
pub use zilpay::background::book::AddressBookEntry;
pub use zilpay::settings::{
    notifications::NotificationState,
    theme::{Appearances, Theme},
};

#[flutter_rust_bridge::frb(dart_async)]
pub async fn create_new_connection(conn: ConnectionInfo) -> Result<(), String> {
    with_service_mut(|core| {
        core.add_connection(conn.into())
            .map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn add_wallet_to_connection(domain: String, wallet_index: usize) -> Result<(), String> {
    with_service_mut(|core| {
        core.add_wallet_to_connection(domain, wallet_index)
            .map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(Into::into)
}

#[flutter_rust_bridge::frb(dart_async)]
pub async fn get_connections_list() -> Result<Vec<ConnectionInfo>, String> {
    with_service(|core| Ok(core.get_connections().into_iter().map(Into::into).collect()))
        .await
        .map_err(Into::into)
}
