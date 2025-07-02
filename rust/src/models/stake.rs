use zilpay::network::zil_stake_parse::FinalOutput;

pub struct FinalOutputInfo {
    pub name: String,
    pub url: String,
    pub address: String,
    pub token_address: Option<String>,
    pub deleg_amt: String,
    pub rewards: String,
    pub tvl: Option<u128>,
    pub vote_power: Option<f64>,
    pub apr: Option<f64>,
    pub commission: Option<f64>,
    pub tag: String,
    pub withdrawal_block: Option<u64>,
    pub current_block: Option<u64>,
    pub price: Option<f64>,
}

impl From<FinalOutput> for FinalOutputInfo {
    fn from(stake: FinalOutput) -> Self {
        FinalOutputInfo {
            name: stake.name,
            url: stake.url,
            address: stake.address,
            token_address: stake.token_address,
            deleg_amt: stake.deleg_amt.to_string(),
            rewards: stake.rewards.to_string(),
            tvl: stake.tvl,
            vote_power: stake.vote_power,
            apr: stake.apr,
            commission: stake.commission,
            tag: stake.tag,
            withdrawal_block: stake.withdrawal_block,
            current_block: stake.current_block,
            price: stake.price,
        }
    }
}

impl From<FinalOutputInfo> for FinalOutput {
    fn from(stake: FinalOutputInfo) -> Self {
        FinalOutput {
            name: stake.name,
            url: stake.url,
            address: stake.address,
            token_address: stake.token_address,
            deleg_amt: stake.deleg_amt.parse().unwrap_or_default(),
            rewards: stake.rewards.parse().unwrap_or_default(),
            tvl: stake.tvl,
            vote_power: stake.vote_power,
            apr: stake.apr,
            commission: stake.commission,
            tag: stake.tag,
            withdrawal_block: stake.withdrawal_block,
            current_block: stake.current_block,
            price: stake.price,
        }
    }
}
