use crate::{
    models::connection::ConnectionInfo,
    utils::{errors::ServiceError, utils::with_service},
};
pub use zilpay::background::bg_connections::ConnectionManagement;
pub use zilpay::background::book::AddressBookEntry;
pub use zilpay::settings::{
    notifications::NotificationState,
    theme::{Appearances, Theme},
};

pub async fn create_update_connection(
    wallet_index: usize,
    conn: ConnectionInfo,
) -> Result<(), String> {
    with_service(|core| {
        let mut connections = core.get_connections(wallet_index);

        if let Some(existing_conn) = connections.iter_mut().find(|c| c.domain == conn.domain) {
            *existing_conn = conn.into();
            core.save_connection(wallet_index, connections)?;
        } else {
            core.add_connection(wallet_index, conn.into())
                .map_err(ServiceError::BackgroundError)?;
        }

        Ok(())
    })
    .await
    .map_err(Into::into)
}

pub async fn remove_connections(wallet_index: usize, domain: String) -> Result<(), String> {
    with_service(|core| {
        core.remove_connection(wallet_index, &domain)
            .map_err(ServiceError::BackgroundError)
    })
    .await
    .map_err(Into::into)
}

pub async fn get_connections_list(wallet_index: usize) -> Result<Vec<ConnectionInfo>, String> {
    with_service(|core| {
        Ok(core
            .get_connections(wallet_index)
            .into_iter()
            .map(Into::into)
            .collect())
    })
    .await
    .map_err(Into::into)
}
