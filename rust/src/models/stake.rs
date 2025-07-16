use super::ftoken::FTokenInfo;
use zilpay::network::stake::{FinalOutput, LPToken, PendingWithdrawal, ZilValidator};

pub struct PendingWithdrawalInfo {
    pub amount: String,
    pub withdrawal_block: u64,
    pub claimable: bool,
}

pub struct ZilValidatorInfo {
    pub future_stake: String,
    pub pending_withdrawals: String,
    pub reward_address: String,
    pub status: bool,
}

pub struct FinalOutputInfo {
    pub name: String,
    pub address: String,
    pub token: Option<FTokenInfo>,
    pub deleg_amt: String,
    pub rewards: String,
    pub claimable_amount: String,
    pub vote_power: Option<f64>,
    pub apr: Option<f64>,
    pub commission: Option<f64>,
    pub total_rewards: Option<String>,
    pub total_stake: Option<String>,
    pub total_network_stake: Option<String>,
    pub version: Option<String>,
    pub unbonding_period: Option<String>,
    pub tag: String,
    pub current_block: Option<u64>,
    pub pending_withdrawals: Vec<PendingWithdrawalInfo>,
    pub validators: Vec<ZilValidatorInfo>,
    pub hide: bool,
    pub uptime: u8,
    pub can_stake: bool,
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

impl From<ZilValidator> for ZilValidatorInfo {
    fn from(value: ZilValidator) -> Self {
        Self {
            future_stake: value.future_stake.to_string(),
            pending_withdrawals: value.pending_withdrawals.to_string(),
            reward_address: value.reward_address.to_string(),
            status: value.status,
        }
    }
}

impl From<ZilValidatorInfo> for ZilValidator {
    fn from(value: ZilValidatorInfo) -> Self {
        Self {
            future_stake: value.future_stake.parse().unwrap_or_default(),
            pending_withdrawals: value.pending_withdrawals.parse().unwrap_or_default(),
            reward_address: value.reward_address.parse().unwrap_or_default(),
            status: value.status,
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
            vote_power: stake.vote_power,
            apr: stake.apr,
            commission: stake.commission,
            tag: stake.tag,
            current_block: stake.current_block,
            pending_withdrawals: stake.pending_withdrawals.into_iter().map(Into::into).collect(),
            hide: stake.hide,
            uptime: stake.uptime,
            can_stake: stake.can_stake,
            claimable_amount: stake.claimable_amount.to_string(),
            total_rewards: stake.total_rewards.map(|v| v.to_string()),
            total_stake: stake.total_stake.map(|v| v.to_string()),
            total_network_stake: stake.total_network_stake.map(|v| v.to_string()),
            version: stake.version,
            unbonding_period: stake.unbonding_period.map(|v| v.to_string()),
            validators: stake.validators.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<FinalOutputInfo> for FinalOutput {
    fn from(stake: FinalOutputInfo) -> Self {
        FinalOutput {
            name: stake.name,
            address: stake.address,
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
            vote_power: stake.vote_power,
            apr: stake.apr,
            commission: stake.commission,
            total_rewards: stake.total_rewards.and_then(|v| v.parse().ok()),
            total_stake: stake.total_stake.and_then(|v| v.parse().ok()),
            total_network_stake: stake.total_network_stake.and_then(|v| v.parse().ok()),
            version: stake.version,
            unbonding_period: stake.unbonding_period.and_then(|v| v.parse().ok()),
            tag: stake.tag,
            current_block: stake.current_block,
            pending_withdrawals: stake
                .pending_withdrawals
                .into_iter()
                .map(Into::into)
                .collect(),
            validators: stake.validators.into_iter().map(Into::into).collect(),
            hide: stake.hide,
            uptime: stake.uptime,
            can_stake: stake.can_stake,
        }
    }
}
