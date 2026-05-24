use zilpay::background::bg_wallet::WalletManagement;
use zilpay::wallet::wallet_storage::StorageOperations;

use crate::models::{
    exchange::{
        build_exchange_chain_groups, thorchain, ExchangeChainGroup, ExchangeProviderId,
        ExchangeProviderMetadata, ExchangeQuoteResult,
    },
    ftoken::FTokenInfo,
    provider::NetworkConfigInfo,
};
use crate::service::background::BACKGROUND_SERVICE;
use crate::utils::errors::ServiceError;

pub async fn bootstrap_exchange_providers(
    configs: Vec<NetworkConfigInfo>,
    wallet_index: usize,
) -> Result<(Vec<ExchangeProviderId>, Vec<FTokenInfo>), String> {
    if configs.is_empty() {
        return Ok((Vec::with_capacity(0), Vec::with_capacity(0)));
    }

    let wallet_tokens: Vec<FTokenInfo> = {
        let guard = BACKGROUND_SERVICE.read().await;
        let service = guard.as_ref().ok_or(ServiceError::NotRunning)?;
        let wallet = service
            .core
            .get_wallet_by_index(wallet_index)
            .map_err(ServiceError::BackgroundError)?;
        wallet
            .get_ftokens()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?
            .into_iter()
            .map(|t| t.into())
            .collect()
    };

    let candidates = [ExchangeProviderId::Thorchain];
    let mut result = Vec::with_capacity(candidates.len());

    for candidate in candidates {
        if configs.iter().any(|c| candidate.is_supported(c)) {
            result.push(candidate);
        }
    }

    Ok((result, wallet_tokens))
}

pub async fn fetch_exchange_assets(
    provider: ExchangeProviderId,
    configs: Vec<NetworkConfigInfo>,
    wallet_tokens: Vec<FTokenInfo>,
) -> Result<Vec<ExchangeChainGroup>, String> {
    match provider {
        ExchangeProviderId::Thorchain => {
            let meta = thorchain::fetch_thorchain_metadata().await?;
            let metadata = ExchangeProviderMetadata::Thorchain(meta);
            Ok(build_exchange_chain_groups(
                &configs,
                &metadata,
                &wallet_tokens,
            ))
        }
    }
}

pub async fn fetch_exchange_quote(
    provider: ExchangeProviderId,
    from_asset: String,
    to_asset: String,
    amount: String,
    destination: String,
) -> Result<ExchangeQuoteResult, String> {
    match provider {
        ExchangeProviderId::Thorchain => {
            let quote = thorchain::fetch_thorchain_swap_quote(
                &from_asset,
                &to_asset,
                &amount,
                &destination,
            )
            .await?;
            Ok(quote.into_quote_result())
        }
    }
}
