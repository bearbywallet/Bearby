mod bootstrap;
mod evm;
mod ledger;
mod svm;

// Flutter-facing re-exports — only what FRB needs to see.
pub use bootstrap::{bootstrap_exchange_providers, refresh_exchange_quotes};
pub use ledger::{
    PreparedSwapInfo, check_exchange_approval, estimate_swap_base_nonce, finalize_exchange_swap,
    prepare_exchange_swap,
};

use crate::frb_generated::StreamSink;
use crate::models::exchange::{ExchangeTxDisplay, SwapAuth, SwapParams};
use crate::models::exchange::relay::RelayOrigin;
use crate::models::transactions::history::HistoricalTransactionInfo;

pub async fn execute_exchange_swap(
    auth: SwapAuth,
    params: SwapParams,
    display: ExchangeTxDisplay,
    sink: StreamSink<String>,
) -> Result<Vec<HistoricalTransactionInfo>, String> {
    if params.provider.is_relay() {
        return match RelayOrigin::from_addr_type(params.from.token.addr_type) {
            Some(RelayOrigin::Svm) => {
                svm::execute_svm_exchange_swap(auth, params, display, sink).await
            }
            Some(RelayOrigin::Btc) => {
                Err("Relay Bitcoin-origin swaps are not supported yet".to_string())
            }
            Some(RelayOrigin::Tron) => {
                Err("Relay TRON-origin swaps are not supported yet".to_string())
            }
            Some(RelayOrigin::Evm) | None => {
                evm::execute_evm_exchange_swap(auth, params, display, sink).await
            }
        };
    }

    evm::execute_evm_exchange_swap(auth, params, display, sink).await
}
