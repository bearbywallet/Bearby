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
        }
    }
}
