use zilpay::network::zil_stake_parse::{FinalOutput, LPToken, PendingWithdrawal};

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
    pub tvl: Option<u128>,
    pub vote_power: Option<f64>,
    pub apr: Option<f64>,
    pub price: Option<f64>,
    pub commission: Option<f64>,
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
            token: stake.token.and_then(|t| {
                Some(FTokenInfo {
                    name: t.name,
                    symbol: t.symbol,
                    decimals: t.decimals,
                    addr: t.address.to_string(),
                    addr_type: 1,
                    chain_hash: 0,
                    native: false,
                    default: false,
                    logo: Some("https://raw.githubusercontent.com/zilpay/tokens_meta/refs/heads/master/ft/zilliqa/%{contract_address}%/%{dark,light}%.webp".to_string()),
                    rate: stake.price.unwrap_or(0.0),
                    balances: Default::default(),
                })
            }),
            deleg_amt: stake.deleg_amt.to_string(),
            rewards: stake.rewards.to_string(),
            tvl: stake.tvl,
            vote_power: stake.vote_power,
            apr: stake.apr,
            commission: stake.commission,
            tag: stake.tag,
            current_block: stake.current_block,
            price: stake.price,
            pending_withdrawals: stake
                .pending_withdrawals
                .into_iter()
                .map(|v| v.into())
                .collect(),
        }
    }
}

impl From<FinalOutputInfo> for FinalOutput {
    fn from(stake: FinalOutputInfo) -> Self {
        FinalOutput {
            name: stake.name,
            address: stake.address,
            token: stake.token.and_then(|t| {
                Some(LPToken {
                    name: t.name,
                    symbol: t.symbol,
                    decimals: t.decimals,
                    address: t.addr.parse().unwrap_or_default(),
                })
            }),
            deleg_amt: stake.deleg_amt.parse().unwrap_or_default(),
            rewards: stake.rewards.parse().unwrap_or_default(),
            tvl: stake.tvl,
            vote_power: stake.vote_power,
            apr: stake.apr,
            commission: stake.commission,
            tag: stake.tag,
            current_block: stake.current_block,
            price: stake.price,
            pending_withdrawals: stake
                .pending_withdrawals
                .into_iter()
                .map(|v| v.into())
                .collect(),
        }
    }
}
