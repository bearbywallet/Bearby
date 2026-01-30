use zilpay::network::zil::{FinalOutput, LPToken, PendingWithdrawal};

use super::ftoken::FTokenInfo;

pub struct PendingWithdrawalInfo {
    pub amount: String,
    pub withdrawal_block: u64,
    pub claimable: bool,
}

pub struct FinalOutputInfo {
    pub name: String,
    pub address: String,
    pub token: Option<FTokenInfo>,
    pub deleg_amt: String,
    pub rewards: String,
    pub claimable_amount: String,
    pub apr: Option<f64>,
    pub commission: Option<f64>,
    pub unbonding_period_seconds: Option<u64>,
    pub lst_price_change_percent: Option<f32>,
    pub avg_block_time_ms: Option<u64>,
    pub tag: String,
    pub current_block: Option<u64>,
    pub pending_withdrawals: Vec<PendingWithdrawalInfo>,
}

impl From<PendingWithdrawal> for PendingWithdrawalInfo {
    fn from(value: PendingWithdrawal) -> Self {
        Self {
            amount: value.amount.to_string(),
            withdrawal_block: value.withdrawal_block,
            claimable: value.claimable,
        }
    }
}

impl From<PendingWithdrawalInfo> for PendingWithdrawal {
    fn from(value: PendingWithdrawalInfo) -> Self {
        Self {
            amount: value.amount.parse().unwrap_or_default(),
            withdrawal_block: value.withdrawal_block,
            claimable: value.claimable,
        }
    }
}

impl From<FinalOutput> for FinalOutputInfo {
    fn from(stake: FinalOutput) -> Self {
        FinalOutputInfo {
            name: stake.name,
            address: stake.address,
            avg_block_time_ms: stake.avg_block_time_ms,
            token: stake.token.map(|t| FTokenInfo {
                name: t.name,
                symbol: t.symbol,
                decimals: t.decimals,
                addr: t.address.to_string(),
                addr_type: 1,
                chain_hash: 0,
                native: false,
                default: false,
                logo: Some("https://raw.githubusercontent.com/zilpay/tokens_meta/refs/heads/master/ft/zilliqa/%{contract_address}%/%{dark,light}%.webp".to_string()),
                rate: t.price.unwrap_or(0.0),
                balances: Default::default(),
            }),
            deleg_amt: stake.deleg_amt.to_string(),
            rewards: stake.rewards.to_string(),
            apr: stake.apr,
            commission: stake.commission,
                        unbonding_period_seconds: stake.unbonding_period_seconds,
            tag: stake.tag,
            current_block: stake.current_block,
            pending_withdrawals: stake.pending_withdrawals.into_iter().map(Into::into).collect(),
            claimable_amount: stake.claimable_amount.to_string(),
            lst_price_change_percent: stake.lst_price_change_percent,
        }
    }
}

impl From<FinalOutputInfo> for FinalOutput {
    fn from(stake: FinalOutputInfo) -> Self {
        FinalOutput {
            name: stake.name,
            address: stake.address,
            avg_block_time_ms: stake.avg_block_time_ms,
            token: stake.token.map(|t| LPToken {
                name: t.name,
                symbol: t.symbol,
                decimals: t.decimals,
                address: t.addr.parse().unwrap_or_default(),
                price: Default::default(),
            }),
            deleg_amt: stake.deleg_amt.parse().unwrap_or_default(),
            rewards: stake.rewards.parse().unwrap_or_default(),
            claimable_amount: stake.claimable_amount.parse().unwrap_or_default(),
            apr: stake.apr,
            unbonding_period_seconds: stake.unbonding_period_seconds,
            commission: stake.commission,
            tag: stake.tag,
            lst_price_change_percent: stake.lst_price_change_percent,
            current_block: stake.current_block,
            pending_withdrawals: stake
                .pending_withdrawals
                .into_iter()
                .map(Into::into)
                .collect(),
        }
    }
}
