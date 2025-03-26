#[cfg(test)]
mod wallet_tests {
    use tempfile::tempdir;

    use crate::{
        api::{
            backend::{get_data, load_service},
            utils::bip39_checksum_valid,
        },
        service::service::BACKGROUND_SERVICE,
    };

    #[tokio::test]
    async fn test_init_service() {
        let dir = tempdir().unwrap();

        load_service(dir.path().to_str().unwrap()).await.unwrap();

        let wallet_state = get_data().await.unwrap();

        assert_eq!(wallet_state.wallets.len(), 0);
        assert_eq!(wallet_state.providers.len(), 0);
        assert_eq!(wallet_state.notifications_wallet_states.len(), 0);
        assert_eq!(wallet_state.notifications_global_enabled, false);
        assert_eq!(wallet_state.locale, None);
        assert_eq!(wallet_state.appearances, 0);
        assert_eq!(wallet_state.abbreviated_number, true);

        assert_eq!(wallet_state.browser_settings.search_engine_index, 0);
        assert_eq!(wallet_state.browser_settings.cache_enabled, true);
        assert_eq!(wallet_state.browser_settings.cookies_enabled, true);
        assert_eq!(wallet_state.browser_settings.content_blocking, 1);
        assert_eq!(wallet_state.browser_settings.do_not_track, false);
        assert_eq!(wallet_state.browser_settings.incognito_mode, false);

        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().unwrap();

        assert!(service.running);
        assert!(service.block_handle.is_none());
        assert!(service.history_handle.is_none());
    }

    #[test]
    fn test_validate_mnemonic_valid() {
        let valid_mnemonic =
            "use fit skill orphan memory impose attract mobile delay inch ill trophy".to_string();
        assert!(bip39_checksum_valid(valid_mnemonic));
    }

    #[test]
    fn test_validate_mnemonic_invalid() {
        let valid_mnemonic =
            "use fit skill orphan memory impose attract mobile delay inch trophy ill".to_string();
        assert!(!bip39_checksum_valid(valid_mnemonic));
    }
}
