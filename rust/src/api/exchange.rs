use std::collections::HashSet;

use zilpay::background::bg_provider::ProvidersManagement;
use zilpay::rpc::network_config::ChainConfig;
use zilpay::token::ft::FToken;
use zilpay::wallet::wallet_storage::StorageOperations;

use crate::models::exchange::{ExchangeAsset, ExchangeProvider};
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;

pub async fn bootstrap_exchange_providers() -> Result<Vec<ExchangeAsset>, String> {
    let condidate = HashSet::from([
        ExchangeProvider::Thorchain(0),
        ExchangeProvider::Uniswap(0),
        ExchangeProvider::ZIlSwap(0),
    ]);
    let all_ftokens: Vec<ExchangeAsset> = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        let mut seen = HashSet::new();
        let all_chain: Vec<ChainConfig> = service
            .core
            .get_providers()
            .into_iter()
            .map(|n| n.config)
            .collect();
        let all_ftokens: Vec<ExchangeAsset> = service
            .core
            .wallets
            .iter()
            .map(|w| w.get_ftokens().map_err(|e| e.to_string()))
            .collect::<Result<Vec<Vec<FToken>>, String>>()?
            .into_iter()
            .flatten()
            .filter_map(|t: FToken| {
                if !seen.insert(t.addr.to_hash()) {
                    return None;
                }

                let slip44 = all_chain.iter().find(|c| c.hash() == t.chain_hash)?.slip_44;
                let providers: HashSet<ExchangeProvider> = condidate
                    .iter()
                    .filter(|p| p.is_support(t.addr.prefix_type(), slip44))
                    .cloned()
                    .collect();

                if providers.is_empty() {
                    return None;
                }
                Some(ExchangeAsset {
                    token: t.into(),
                    providers,
                    halted: true,
                })
            })
            .collect();

        all_ftokens
    }
    .into_iter()
    .collect();

    Ok(all_ftokens)
}

pub async fn fetch_exchange_quote(
    asset: ExchangeAsset,
    from_asset: String,
    to_asset: String,
    amount: String,
    destination: String,
) -> Result<(), String> {
    Ok(())
}
