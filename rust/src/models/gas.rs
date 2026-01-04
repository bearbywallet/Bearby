use zilpay::network::evm::{GasFeeHistory, RequiredTxParams};

#[derive(Default, Debug)]
pub struct GasFeeHistoryInfo {
    pub max_fee: u128,
    pub priority_fee: u128,
    pub base_fee: u128,
}

impl From<GasFeeHistory> for GasFeeHistoryInfo {
    fn from(value: GasFeeHistory) -> Self {
        Self {
            max_fee: value.max_fee.try_into().unwrap_or_default(),
            priority_fee: value.priority_fee.try_into().unwrap_or_default(),
            base_fee: value.base_fee.try_into().unwrap_or_default(),
        }
    }
}
impl From<GasFeeHistoryInfo> for GasFeeHistory {
    fn from(value: GasFeeHistoryInfo) -> Self {
        Self {
            max_fee: value.max_fee.try_into().unwrap_or_default(),
            priority_fee: value.priority_fee.try_into().unwrap_or_default(),
            base_fee: value.base_fee.try_into().unwrap_or_default(),
        }
    }
}

#[derive(Default, Debug)]
pub struct RequiredTxParamsInfo {
    pub gas_price: u128,
    pub max_priority_fee: u128,
    pub fee_history: GasFeeHistoryInfo,
    pub tx_estimate_gas: u64,
    pub blob_base_fee: u128,
    pub nonce: u64,
    pub slow: u64,
    pub market: u64,
    pub fast: u64,
    pub current: u64,
}

impl From<RequiredTxParams> for RequiredTxParamsInfo {
    fn from(value: RequiredTxParams) -> Self {
        Self {
            gas_price: value.gas_price.try_into().unwrap_or_default(),
            max_priority_fee: value.max_priority_fee.try_into().unwrap_or_default(),
            fee_history: value.fee_history.into(),
            tx_estimate_gas: value.tx_estimate_gas.try_into().unwrap_or_default(),
            blob_base_fee: value.blob_base_fee.try_into().unwrap_or_default(),
            nonce: value.nonce,
            slow: value.slow,
            market: value.market,
            fast: value.fast,
            current: value.current,
        }
    }
}

impl From<RequiredTxParamsInfo> for RequiredTxParams {
    fn from(value: RequiredTxParamsInfo) -> Self {
        Self {
            gas_price: value.gas_price.try_into().unwrap_or_default(),
            max_priority_fee: value.max_priority_fee.try_into().unwrap_or_default(),
            fee_history: value.fee_history.try_into().unwrap_or_default(),
            tx_estimate_gas: value.tx_estimate_gas.try_into().unwrap_or_default(),
            blob_base_fee: value.blob_base_fee.try_into().unwrap_or_default(),
            nonce: value.nonce,
            slow: value.slow,
            market: value.market,
            fast: value.fast,
            current: value.current,
        }
    }
}
