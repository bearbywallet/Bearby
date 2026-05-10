use std::collections::HashMap;
use std::str::FromStr;

use zilpay::proto::address::Address;
use zilpay::proto::btc_utils::{
    AddressChain, BtcAccountXpubsInput, BtcAddressEntry, ByteCodec, Utxo,
};

use crate::utils::errors::ServiceError;

pub fn btc_chain_info_map_to_core(
    input: HashMap<u8, AddressChainInfo>,
) -> Result<HashMap<bitcoin::AddressType, AddressChain>, ServiceError> {
    input
        .into_iter()
        .map(|(addr_type_byte, chain_info)| {
            let addr_type = bitcoin::AddressType::from_byte(addr_type_byte)
                .map_err(|e| ServiceError::ParseError("address_type".into(), e.to_string()))?;
            let chain = chain_info.try_into()?;
            Ok((addr_type, chain))
        })
        .collect()
}

#[derive(Debug, PartialEq)]
pub struct BtcAccountXpubsInputInfo {
    pub bip44_xpub: String,
    pub bip49_xpub: String,
    pub bip84_xpub: String,
    pub bip86_xpub: String,
}

#[derive(Debug, PartialEq)]
pub struct UtxoInfo {
    pub txid: String,
    pub vout: u32,
    pub value: u64,
    pub height: u32,
}

#[derive(Debug, PartialEq)]
pub struct BtcAddressEntryInfo {
    pub address: String,
    pub path: String,
    pub history: Vec<String>,
    pub utxos: Vec<UtxoInfo>,
}

#[derive(Debug, PartialEq)]
pub struct AddressChainInfo {
    pub external: Vec<BtcAddressEntryInfo>,
    pub internal: Vec<BtcAddressEntryInfo>,
}

impl TryFrom<BtcAccountXpubsInputInfo> for BtcAccountXpubsInput {
    type Error = ServiceError;

    fn try_from(value: BtcAccountXpubsInputInfo) -> Result<Self, Self::Error> {
        Ok(Self {
            bip44_xpub: bitcoin::bip32::Xpub::from_str(&value.bip44_xpub)
                .map_err(|e| ServiceError::ParseError("bip44_xpub".into(), e.to_string()))?,
            bip49_xpub: bitcoin::bip32::Xpub::from_str(&value.bip49_xpub)
                .map_err(|e| ServiceError::ParseError("bip49_xpub".into(), e.to_string()))?,
            bip84_xpub: bitcoin::bip32::Xpub::from_str(&value.bip84_xpub)
                .map_err(|e| ServiceError::ParseError("bip84_xpub".into(), e.to_string()))?,
            bip86_xpub: bitcoin::bip32::Xpub::from_str(&value.bip86_xpub)
                .map_err(|e| ServiceError::ParseError("bip86_xpub".into(), e.to_string()))?,
        })
    }
}

impl From<Utxo> for UtxoInfo {
    fn from(value: Utxo) -> Self {
        Self {
            txid: value.txid.to_string(),
            vout: value.vout,
            value: value.value,
            height: value.height,
        }
    }
}

impl TryFrom<UtxoInfo> for Utxo {
    type Error = ServiceError;

    fn try_from(value: UtxoInfo) -> Result<Self, Self::Error> {
        Ok(Self {
            txid: bitcoin::Txid::from_str(&value.txid)
                .map_err(|e| ServiceError::ParseError("txid".into(), e.to_string()))?,
            vout: value.vout,
            value: value.value,
            height: value.height,
        })
    }
}

impl From<BtcAddressEntry> for BtcAddressEntryInfo {
    fn from(value: BtcAddressEntry) -> Self {
        Self {
            address: value.address.auto_format(),
            path: value.path.to_string(),
            history: value.history.iter().map(|t| t.to_string()).collect(),
            utxos: value.utxos.into_iter().map(Into::into).collect(),
        }
    }
}

impl TryFrom<BtcAddressEntryInfo> for BtcAddressEntry {
    type Error = ServiceError;

    fn try_from(value: BtcAddressEntryInfo) -> Result<Self, Self::Error> {
        Ok(Self {
            address: Address::from_bitcoin_address(&value.address)?,
            path: zilpay::crypto::bip49::DerivationPath::try_from(value.path.as_str())
                .map_err(|e| ServiceError::ParseError("derivation_path".into(), e.to_string()))?,
            history: value
                .history
                .into_iter()
                .map(|h| {
                    bitcoin::Txid::from_str(&h)
                        .map_err(|e| ServiceError::ParseError("txid".into(), e.to_string()))
                })
                .collect::<Result<Vec<_>, ServiceError>>()?,
            utxos: value
                .utxos
                .into_iter()
                .map(TryInto::try_into)
                .collect::<Result<Vec<_>, ServiceError>>()?,
        })
    }
}

impl From<AddressChain> for AddressChainInfo {
    fn from(value: AddressChain) -> Self {
        Self {
            external: value.external.into_iter().map(Into::into).collect(),
            internal: value.internal.into_iter().map(Into::into).collect(),
        }
    }
}

impl TryFrom<AddressChainInfo> for AddressChain {
    type Error = ServiceError;

    fn try_from(value: AddressChainInfo) -> Result<Self, Self::Error> {
        Ok(Self {
            external: value
                .external
                .into_iter()
                .map(TryInto::try_into)
                .collect::<Result<Vec<_>, ServiceError>>()?,
            internal: value
                .internal
                .into_iter()
                .map(TryInto::try_into)
                .collect::<Result<Vec<_>, ServiceError>>()?,
        })
    }
}
