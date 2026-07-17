use flutter_rust_bridge::frb;
pub use zilpay::errors::tx::TransactionErrors;
pub use zilpay::proto::tron_tx::{
    TronTransactionReceipt, TronWebContract, TronWebParameter, TronWebRawData, TronWebTransaction,
};
use zilpay::serde_json;

/// FFI mirror of core `TronTransactionReceipt` (history path).
/// Byte fields are hex-encoded strings for FRB/Dart.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TransactionTron {
    pub raw_data_bytes: String,
    pub tx_id: String,
    pub signature: String,
    pub owner_address: String,
}

impl From<TronTransactionReceipt> for TransactionTron {
    fn from(value: TronTransactionReceipt) -> Self {
        Self {
            raw_data_bytes: zilpay::alloy::hex::encode(value.raw_data_bytes),
            tx_id: zilpay::alloy::hex::encode(value.tx_id),
            signature: zilpay::alloy::hex::encode(value.signature),
            owner_address: value.owner_address.auto_format(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TronVoteInfo {
    pub vote_address: String,
    pub vote_count: i64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TronContractValue {
    TransferContract {
        owner_address: String,
        to_address: String,
        amount: i64,
    },
    TriggerSmartContract {
        owner_address: Option<String>,
        contract_address: Option<String>,
        call_value: Option<i64>,
        data: Option<String>,
        call_token_value: Option<i64>,
        token_id: Option<i64>,
    },
    FreezeBalanceV2Contract {
        owner_address: String,
        frozen_balance: i64,
        resource: i32,
    },
    WithdrawBalanceContract {
        owner_address: String,
    },
    UnfreezeBalanceV2Contract {
        owner_address: String,
        unfreeze_balance: i64,
        resource: i32,
    },
    WithdrawExpireUnfreezeContract {
        owner_address: String,
    },
    DelegateResourceContract {
        owner_address: String,
        resource: i32,
        balance: i64,
        receiver_address: String,
        lock: bool,
        lock_period: i64,
    },
    UnDelegateResourceContract {
        owner_address: String,
        resource: i32,
        balance: i64,
        receiver_address: String,
    },
    CancelAllUnfreezeV2Contract {
        owner_address: String,
    },
    TransferAssetContract {
        asset_name: String,
        owner_address: String,
        to_address: String,
        amount: i64,
    },
    VoteWitnessContract {
        owner_address: String,
        votes: Vec<TronVoteInfo>,
        support: bool,
    },
    AccountCreateContract {
        owner_address: String,
        account_address: String,
    },
    AccountUpdateContract {
        owner_address: String,
        account_name: String,
    },
    AccountPermissionUpdateContract {
        owner_address: String,
    },
    Unknown {
        type_url: String,
        value_json: String,
    },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TronContractInfo {
    pub contract_type: String,
    pub type_url: String,
    pub value: TronContractValue,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TronRawDataInfo {
    pub contract: Vec<TronContractInfo>,
    pub ref_block_bytes: String,
    pub ref_block_hash: String,
    pub expiration: i64,
    pub fee_limit: Option<i64>,
    pub timestamp: i64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TransactionRequestTron {
    pub visible: Option<bool>,
    pub tx_id: Option<String>,
    pub raw_data: TronRawDataInfo,
    pub raw_data_hex: String,
}

fn extract_str_from(value: &serde_json::Value, key: &str) -> Result<String, TransactionErrors> {
    value
        .get(key)
        .and_then(serde_json::Value::as_str)
        .map(String::from)
        .ok_or(TransactionErrors::InvalidContract)
}

fn extract_i64_from(value: &serde_json::Value, key: &str) -> Result<i64, TransactionErrors> {
    value
        .get(key)
        .and_then(serde_json::Value::as_i64)
        .ok_or(TransactionErrors::InvalidContract)
}

fn extract_i32_from(value: &serde_json::Value, key: &str) -> Result<i32, TransactionErrors> {
    extract_i64_from(value, key)
        .and_then(|number| i32::try_from(number).map_err(|_| TransactionErrors::InvalidContract))
}

fn extract_bool_from(value: &serde_json::Value, key: &str) -> Result<bool, TransactionErrors> {
    value
        .get(key)
        .and_then(serde_json::Value::as_bool)
        .ok_or(TransactionErrors::InvalidContract)
}

fn optional_str_from(value: &serde_json::Value, key: &str) -> Option<String> {
    value
        .get(key)
        .and_then(serde_json::Value::as_str)
        .map(String::from)
}

fn optional_i64_from(value: &serde_json::Value, key: &str) -> Option<i64> {
    value.get(key).and_then(serde_json::Value::as_i64)
}

impl TronContractValue {
    #[frb(ignore)]
    pub fn try_from_json(
        type_url: &str,
        value: &serde_json::Value,
    ) -> Result<Self, TransactionErrors> {
        match type_url {
            "type.googleapis.com/protocol.TransferContract" => Ok(Self::TransferContract {
                owner_address: extract_str_from(value, "owner_address")?,
                to_address: extract_str_from(value, "to_address")?,
                amount: extract_i64_from(value, "amount")?,
            }),
            "type.googleapis.com/protocol.TriggerSmartContract" => Ok(Self::TriggerSmartContract {
                owner_address: optional_str_from(value, "owner_address"),
                contract_address: optional_str_from(value, "contract_address"),
                call_value: optional_i64_from(value, "call_value"),
                data: optional_str_from(value, "data"),
                call_token_value: optional_i64_from(value, "call_token_value"),
                token_id: optional_i64_from(value, "token_id"),
            }),
            "type.googleapis.com/protocol.FreezeBalanceV2Contract" => {
                Ok(Self::FreezeBalanceV2Contract {
                    owner_address: extract_str_from(value, "owner_address")?,
                    frozen_balance: extract_i64_from(value, "frozen_balance")?,
                    resource: extract_i32_from(value, "resource")?,
                })
            }
            "type.googleapis.com/protocol.UnfreezeBalanceV2Contract" => {
                Ok(Self::UnfreezeBalanceV2Contract {
                    owner_address: extract_str_from(value, "owner_address")?,
                    unfreeze_balance: extract_i64_from(value, "unfreeze_balance")?,
                    resource: extract_i32_from(value, "resource")?,
                })
            }
            "type.googleapis.com/protocol.WithdrawBalanceContract" => {
                Ok(Self::WithdrawBalanceContract {
                    owner_address: extract_str_from(value, "owner_address")?,
                })
            }
            "type.googleapis.com/protocol.WithdrawExpireUnfreezeContract" => {
                Ok(Self::WithdrawExpireUnfreezeContract {
                    owner_address: extract_str_from(value, "owner_address")?,
                })
            }
            "type.googleapis.com/protocol.DelegateResourceContract" => {
                Ok(Self::DelegateResourceContract {
                    owner_address: extract_str_from(value, "owner_address")?,
                    resource: extract_i32_from(value, "resource")?,
                    balance: extract_i64_from(value, "balance")?,
                    receiver_address: extract_str_from(value, "receiver_address")?,
                    lock: extract_bool_from(value, "lock")?,
                    lock_period: extract_i64_from(value, "lock_period")?,
                })
            }
            "type.googleapis.com/protocol.UnDelegateResourceContract" => {
                Ok(Self::UnDelegateResourceContract {
                    owner_address: extract_str_from(value, "owner_address")?,
                    resource: extract_i32_from(value, "resource")?,
                    balance: extract_i64_from(value, "balance")?,
                    receiver_address: extract_str_from(value, "receiver_address")?,
                })
            }
            "type.googleapis.com/protocol.CancelAllUnfreezeV2Contract" => {
                Ok(Self::CancelAllUnfreezeV2Contract {
                    owner_address: extract_str_from(value, "owner_address")?,
                })
            }
            "type.googleapis.com/protocol.TransferAssetContract" => {
                Ok(Self::TransferAssetContract {
                    asset_name: extract_str_from(value, "asset_name")?,
                    owner_address: extract_str_from(value, "owner_address")?,
                    to_address: extract_str_from(value, "to_address")?,
                    amount: extract_i64_from(value, "amount")?,
                })
            }
            "type.googleapis.com/protocol.VoteWitnessContract" => {
                let raw_votes = value
                    .get("votes")
                    .and_then(serde_json::Value::as_array)
                    .ok_or(TransactionErrors::InvalidContract)?;
                let votes = raw_votes
                    .iter()
                    .map(|vote| {
                        Ok(TronVoteInfo {
                            vote_address: extract_str_from(vote, "vote_address")?,
                            vote_count: extract_i64_from(vote, "vote_count")?,
                        })
                    })
                    .collect::<Result<Vec<_>, TransactionErrors>>()?;
                Ok(Self::VoteWitnessContract {
                    owner_address: extract_str_from(value, "owner_address")?,
                    votes,
                    support: extract_bool_from(value, "support")?,
                })
            }
            "type.googleapis.com/protocol.AccountCreateContract" => {
                Ok(Self::AccountCreateContract {
                    owner_address: extract_str_from(value, "owner_address")?,
                    account_address: extract_str_from(value, "account_address")?,
                })
            }
            "type.googleapis.com/protocol.AccountUpdateContract" => {
                Ok(Self::AccountUpdateContract {
                    owner_address: extract_str_from(value, "owner_address")?,
                    account_name: extract_str_from(value, "account_name")?,
                })
            }
            "type.googleapis.com/protocol.AccountPermissionUpdateContract" => {
                Ok(Self::AccountPermissionUpdateContract {
                    owner_address: extract_str_from(value, "owner_address")?,
                })
            }
            _ => Ok(Self::Unknown {
                type_url: String::from(type_url),
                value_json: value.to_string(),
            }),
        }
    }

    #[frb(ignore)]
    pub fn as_json_value(&self) -> Result<serde_json::Value, TransactionErrors> {
        match self {
            Self::TransferContract {
                owner_address,
                to_address,
                amount,
            } => Ok(serde_json::json!({
                "owner_address": owner_address,
                "to_address": to_address,
                "amount": amount
            })),
            Self::TriggerSmartContract {
                owner_address,
                contract_address,
                call_value,
                data,
                call_token_value,
                token_id,
            } => {
                let mut map = serde_json::Map::with_capacity(6);
                if let Some(value) = owner_address {
                    map.insert(
                        "owner_address".into(),
                        serde_json::Value::String(String::from(value)),
                    );
                }
                if let Some(value) = contract_address {
                    map.insert(
                        "contract_address".into(),
                        serde_json::Value::String(String::from(value)),
                    );
                }
                if let Some(value) = call_value {
                    map.insert("call_value".into(), (*value).into());
                }
                if let Some(value) = data {
                    map.insert(
                        "data".into(),
                        serde_json::Value::String(String::from(value)),
                    );
                }
                if let Some(value) = call_token_value {
                    map.insert("call_token_value".into(), (*value).into());
                }
                if let Some(value) = token_id {
                    map.insert("token_id".into(), (*value).into());
                }
                Ok(serde_json::Value::Object(map))
            }
            Self::FreezeBalanceV2Contract {
                owner_address,
                frozen_balance,
                resource,
            } => Ok(serde_json::json!({
                "owner_address": owner_address,
                "frozen_balance": frozen_balance,
                "resource": resource
            })),
            Self::UnfreezeBalanceV2Contract {
                owner_address,
                unfreeze_balance,
                resource,
            } => Ok(serde_json::json!({
                "owner_address": owner_address,
                "unfreeze_balance": unfreeze_balance,
                "resource": resource
            })),
            Self::WithdrawBalanceContract { owner_address } => Ok(serde_json::json!({
                "owner_address": owner_address
            })),
            Self::WithdrawExpireUnfreezeContract { owner_address } => Ok(serde_json::json!({
                "owner_address": owner_address
            })),
            Self::DelegateResourceContract {
                owner_address,
                resource,
                balance,
                receiver_address,
                lock,
                lock_period,
            } => Ok(serde_json::json!({
                "owner_address": owner_address,
                "resource": resource,
                "balance": balance,
                "receiver_address": receiver_address,
                "lock": lock,
                "lock_period": lock_period
            })),
            Self::UnDelegateResourceContract {
                owner_address,
                resource,
                balance,
                receiver_address,
            } => Ok(serde_json::json!({
                "owner_address": owner_address,
                "resource": resource,
                "balance": balance,
                "receiver_address": receiver_address
            })),
            Self::CancelAllUnfreezeV2Contract { owner_address } => Ok(serde_json::json!({
                "owner_address": owner_address
            })),
            Self::TransferAssetContract {
                asset_name,
                owner_address,
                to_address,
                amount,
            } => Ok(serde_json::json!({
                "asset_name": asset_name,
                "owner_address": owner_address,
                "to_address": to_address,
                "amount": amount
            })),
            Self::VoteWitnessContract {
                owner_address,
                votes,
                support,
            } => {
                let votes_json = votes
                    .iter()
                    .map(|vote| {
                        serde_json::json!({
                            "vote_address": vote.vote_address,
                            "vote_count": vote.vote_count
                        })
                    })
                    .collect::<Vec<_>>();
                Ok(serde_json::json!({
                    "owner_address": owner_address,
                    "votes": votes_json,
                    "support": support
                }))
            }
            Self::AccountCreateContract {
                owner_address,
                account_address,
            } => Ok(serde_json::json!({
                "owner_address": owner_address,
                "account_address": account_address
            })),
            Self::AccountUpdateContract {
                owner_address,
                account_name,
            } => Ok(serde_json::json!({
                "owner_address": owner_address,
                "account_name": account_name
            })),
            Self::AccountPermissionUpdateContract { owner_address } => Ok(serde_json::json!({
                "owner_address": owner_address
            })),
            Self::Unknown { value_json, .. } => serde_json::from_str(value_json)
                .map_err(|error| TransactionErrors::ConvertTxError(error.to_string())),
        }
    }
}

impl From<TronWebTransaction> for TransactionRequestTron {
    fn from(tx: TronWebTransaction) -> Self {
        let TronWebTransaction {
            visible,
            tx_id,
            raw_data,
            raw_data_hex,
        } = tx;
        let TronWebRawData {
            contract,
            ref_block_bytes,
            ref_block_hash,
            expiration,
            fee_limit,
            timestamp,
        } = raw_data;

        let contract_count = contract.len();
        let contracts =
            contract
                .into_iter()
                .fold(Vec::with_capacity(contract_count), |mut items, contract| {
                    let TronWebContract {
                        contract_type,
                        parameter: TronWebParameter { type_url, value },
                    } = contract;
                    let contract_value = match TronContractValue::try_from_json(&type_url, &value) {
                        Ok(parsed) => parsed,
                        Err(_) => TronContractValue::Unknown {
                            type_url: String::from(&type_url),
                            value_json: value.to_string(),
                        },
                    };
                    items.push(TronContractInfo {
                        contract_type,
                        type_url,
                        value: contract_value,
                    });
                    items
                });

        Self {
            visible,
            tx_id,
            raw_data: TronRawDataInfo {
                contract: contracts,
                ref_block_bytes,
                ref_block_hash,
                expiration,
                fee_limit,
                timestamp,
            },
            raw_data_hex,
        }
    }
}

impl TryFrom<TransactionRequestTron> for TronWebTransaction {
    type Error = TransactionErrors;

    fn try_from(info: TransactionRequestTron) -> Result<Self, Self::Error> {
        let TransactionRequestTron {
            visible,
            tx_id,
            raw_data,
            raw_data_hex,
        } = info;
        let TronRawDataInfo {
            contract,
            ref_block_bytes,
            ref_block_hash,
            expiration,
            fee_limit,
            timestamp,
        } = raw_data;

        let contracts = contract
            .into_iter()
            .map(|contract| {
                Ok(TronWebContract {
                    contract_type: contract.contract_type,
                    parameter: TronWebParameter {
                        type_url: contract.type_url,
                        value: contract.value.as_json_value()?,
                    },
                })
            })
            .collect::<Result<Vec<_>, Self::Error>>()?;

        Ok(Self {
            visible,
            tx_id,
            raw_data: TronWebRawData {
                contract: contracts,
                ref_block_bytes,
                ref_block_hash,
                expiration,
                fee_limit,
                timestamp,
            },
            raw_data_hex,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_raw_data(contract: Vec<TronContractInfo>) -> TronRawDataInfo {
        TronRawDataInfo {
            contract,
            ref_block_bytes: String::from("abcd"),
            ref_block_hash: String::from("1234"),
            expiration: 1_710_000_000,
            fee_limit: Some(15_000_000),
            timestamp: 1_700_000_000,
        }
    }

    #[test]
    fn unknown_contract_round_trips_json_value() -> Result<(), TransactionErrors> {
        let request = TransactionRequestTron {
            visible: Some(false),
            tx_id: Some(String::from("tx-id")),
            raw_data: sample_raw_data(vec![TronContractInfo {
                contract_type: String::from("CustomContract"),
                type_url: String::from("type.googleapis.com/protocol.CustomContract"),
                value: TronContractValue::Unknown {
                    type_url: String::from("type.googleapis.com/protocol.CustomContract"),
                    value_json: String::from(r#"{"owner_address":"41aa","amount":7}"#),
                },
            }]),
            raw_data_hex: String::from("deadbeef"),
        };

        let tx = TronWebTransaction::try_from(request)?;
        let parsed = TransactionRequestTron::from(tx);

        assert_eq!(parsed.raw_data.contract.len(), 1);
        let Some(contract) = parsed.raw_data.contract.first() else {
            return Err(TransactionErrors::InvalidContract);
        };
        assert_eq!(contract.contract_type, "CustomContract");
        assert_eq!(
            contract.type_url,
            "type.googleapis.com/protocol.CustomContract"
        );
        Ok(())
    }

    #[test]
    fn malformed_unknown_contract_is_rejected() {
        let request = TransactionRequestTron {
            visible: None,
            tx_id: None,
            raw_data: sample_raw_data(vec![TronContractInfo {
                contract_type: String::from("BrokenContract"),
                type_url: String::from("type.googleapis.com/protocol.BrokenContract"),
                value: TronContractValue::Unknown {
                    type_url: String::from("type.googleapis.com/protocol.BrokenContract"),
                    value_json: String::from("{"),
                },
            }]),
            raw_data_hex: String::from("00"),
        };

        assert!(TronWebTransaction::try_from(request).is_err());
    }
}
