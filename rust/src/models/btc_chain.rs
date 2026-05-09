use std::collections::HashMap;
use std::str::FromStr;

use zilpay::errors::keypair::PubKeyError;
use zilpay::proto::address::Address;
use zilpay::proto::btc_utils::{AddressChain, BtcAddressEntry, ByteCodec, Utxo};

use crate::utils::errors::ServiceError;

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

#[derive(Debug, PartialEq)]
pub struct BtcChainsInfo(pub HashMap<u8, HashMap<u8, AddressChainInfo>>);

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

impl From<HashMap<u8, HashMap<bitcoin::AddressType, AddressChain>>> for BtcChainsInfo {
    fn from(core: HashMap<u8, HashMap<bitcoin::AddressType, AddressChain>>) -> Self {
        Self(
            core.into_iter()
                .map(|(ledger_index, inner)| {
                    let ffi_inner = inner
                        .into_iter()
                        .map(|(addr_type, chain)| (addr_type.to_byte(), chain.into()))
                        .collect();
                    (ledger_index, ffi_inner)
                })
                .collect(),
        )
    }
}

impl TryFrom<BtcChainsInfo> for HashMap<u8, HashMap<bitcoin::AddressType, AddressChain>> {
    type Error = ServiceError;

    fn try_from(ffi: BtcChainsInfo) -> Result<Self, Self::Error> {
        ffi.0
            .into_iter()
            .map(|(ledger_index, inner)| {
                let core_inner = inner
                    .into_iter()
                    .map(|(addr_type_byte, chain_info)| {
                        let addr_type = bitcoin::AddressType::from_byte(addr_type_byte).map_err(
                            |e: PubKeyError| {
                                ServiceError::ParseError("address_type".into(), e.to_string())
                            },
                        )?;
                        let chain: AddressChain = chain_info.try_into()?;
                        Ok((addr_type, chain))
                    })
                    .collect::<Result<HashMap<_, _>, ServiceError>>()?;
                Ok((ledger_index, core_inner))
            })
            .collect()
    }
}
