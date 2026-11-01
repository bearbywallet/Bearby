use std::collections::HashMap;

use zilpay::background::bg_bitcoin::BitcoinManagement;
use zilpay::{
    background::bg_provider::ProvidersManagement, crypto::bip49::split_path,
    proto::btc_utils::ByteCodec, wallet::wallet_storage::StorageOperations,
};
pub use zilpay::{
    background::{bg_wallet::WalletManagement, BackgroundLedgerParams},
    settings::wallet_settings::WalletSettings,
    wallet::wallet_account::AccountManagement,
};
pub use zilpay::{errors::token::TokenError, token::ft::FToken};
pub use zilpay::{proto::pubkey::PubKey, wallet::LedgerParams};

use zilpay::crypto::slip44;

use crate::{
    models::btc_chain::{btc_chain_info_map_to_core, AddressChainInfo, BtcAccountXpubsInputInfo},
    utils::{
        errors::ServiceError,
        helpers::{get_last_wallet, handle, mutate_core_async, pubkey_from_provider, with_service},
    },
};

pub async fn scan_btc_account_history(
    xpubs: BtcAccountXpubsInputInfo,
    ledger_index: u8,
    chain_hash: u64,
) -> Result<HashMap<u8, AddressChainInfo>, String> {
    let core = handle()?;
    let xpubs = zilpay::proto::btc_utils::BtcAccountXpubsInput::try_from(xpubs)
        .map_err(|e: ServiceError| e.to_string())?;

    let core_result = core
        .scan_btc_account_history(&xpubs, ledger_index, chain_hash)
        .await
        .map_err(|e| e.to_string())?;

    Ok(core_result
        .into_iter()
        .map(|(addr_type, chain)| (addr_type.to_byte(), chain.into()))
        .collect())
}

pub struct LedgerParamsInput {
    pub pub_keys: Vec<(u8, String)>,
    pub wallet_index: usize,
    pub wallet_name: String,
    pub ledger_id: String,
    pub account_names: Vec<String>,
    pub biometric_type: String,
    pub chain_hash: u64,
    pub zilliqa_legacy: bool,
    pub btc_chains: HashMap<u8, HashMap<u8, AddressChainInfo>>,
}

pub async fn add_ledger_wallet(
    params: LedgerParamsInput,
    wallet_settings: crate::models::settings::WalletSettingsInfo,
    ftokens: Vec<crate::models::ftoken::FTokenInfo>,
) -> Result<String, String> {
    let core = handle()?;
    let provider = core
        .get_provider(params.chain_hash)
        .map_err(ServiceError::BackgroundError)?;
    let is_bitcoin = provider.config.slip_44 == slip44::BITCOIN;
    let accounts = params
        .pub_keys
        .into_iter()
        .map(|(ledger_index, key_or_addr)| {
            if is_bitcoin {
                Ok((ledger_index, None))
            } else {
                let pub_key =
                    pubkey_from_provider(&key_or_addr, &provider.config, params.zilliqa_legacy)?;
                Ok((ledger_index, Some(pub_key)))
            }
        })
        .collect::<Result<Vec<(u8, Option<PubKey>)>, ServiceError>>()?;
    let ftokens = ftokens
        .into_iter()
        .map(TryFrom::try_from)
        .collect::<Result<Vec<FToken>, TokenError>>()
        .map_err(ServiceError::TokenError)?;
    let wallet_settings = wallet_settings
        .try_into()
        .map_err(ServiceError::SettingsError)?;

    let btc_chains: HashMap<
        u8,
        HashMap<zilpay::bitcoin::AddressType, zilpay::proto::btc_utils::AddressChain>,
    > = params
        .btc_chains
        .into_iter()
        .map(|(ledger_index, inner)| {
            let core_inner = btc_chain_info_map_to_core(inner)?;
            Ok((ledger_index, core_inner))
        })
        .collect::<Result<HashMap<_, _>, ServiceError>>()
        .map_err(|e: ServiceError| e.to_string())?;

    let params = BackgroundLedgerParams {
        ftokens,
        accounts,
        wallet_settings,
        chain_hash: params.chain_hash,
        account_names: params.account_names,
        wallet_index: params.wallet_index,
        wallet_name: params.wallet_name,
        ledger_id: params.ledger_id.into_bytes(),
        biometric_type: params.biometric_type.into(),
        btc_chains,
    };

    drop(core);

    mutate_core_async(async move |core| {
        core.add_ledger_wallet(params, WalletSettings::default())
            .await
            .map_err(ServiceError::BackgroundError)?;
        let wallet = get_last_wallet(core)?;

        Ok(zilpay::alloy::hex::encode(wallet.wallet_address))
    })
    .await
    .map_err(Into::into)
}

pub async fn add_ledger_account(
    wallet_index: usize,
    ledger_index: u8,
    name: String,
    key_or_addr: Option<String>,
    zilliqa_legacy: bool,
    btc_chain: Option<HashMap<u8, AddressChainInfo>>,
) -> Result<(), String> {
    with_service(|core| {
        let wallet = core.get_wallet_by_index(wallet_index)?;
        let wallet_data = wallet
            .get_wallet_data()
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;
        let provider = core.get_provider(wallet_data.chain_hash)?;
        let is_bitcoin = provider.config.slip_44 == slip44::BITCOIN;

        let pub_key = if is_bitcoin {
            None
        } else {
            let raw = key_or_addr
                .as_deref()
                .ok_or(ServiceError::DecodePublicKey)?;
            Some(pubkey_from_provider(raw, &provider.config, zilliqa_legacy)?)
        };

        let btc_chains = btc_chain.map(btc_chain_info_map_to_core).transpose()?;

        wallet
            .add_ledger_account(name, ledger_index, pub_key, btc_chains, &provider.config)
            .map_err(|e| ServiceError::WalletError(wallet_index, e))?;

        Ok(())
    })
    .await
    .map_err(Into::into)
}

pub async fn ledger_split_path(path: String) -> Result<Vec<u32>, String> {
    split_path(&path).map_err(|e| e.to_string())
}

pub async fn ledger_solana_pubkey_to_address(pubkey: Vec<u8>) -> Result<String, String> {
    if pubkey.len() != 32 {
        return Err("Invalid Solana public key length: expected 32 bytes".to_string());
    }
    let mut prefixed = Vec::with_capacity(33);
    prefixed.push(3u8);
    prefixed.extend_from_slice(&pubkey);
    let pk = PubKey::try_from(prefixed.as_slice()).map_err(|e| e.to_string())?;
    let addr = pk.get_addr().map_err(|e| e.to_string())?;
    Ok(addr.to_string())
}

pub async fn ledger_solana_prepare_offchain_message(
    message: Vec<u8>,
    signer_pubkey: Option<Vec<u8>>,
    signer_address: Option<String>,
) -> Result<Vec<u8>, String> {
    const SIGNING_DOMAIN: &[u8; 16] = b"\xffsolana offchain";
    const APP_DOMAIN_LEN: usize = 32;
    const PUBKEY_LEN: usize = 32;
    const V0_HEADER_LEN: usize = 16 + 1 + APP_DOMAIN_LEN + 1 + 1 + PUBKEY_LEN + 2; // 85 bytes
    const MAX_OFFCHAIN_MESSAGE_LEN: usize = (15 * 1024) - 40 - 8; // 15312 bytes (app-solana PACKET_DATA_SIZE)
    const MAX_BODY_LEN: usize = MAX_OFFCHAIN_MESSAGE_LEN - V0_HEADER_LEN;

    if message.is_empty() {
        return Err("Message cannot be empty".to_string());
    }

    if message.len() > V0_HEADER_LEN && message.starts_with(SIGNING_DOMAIN) && message[16] == 0 {
        let signer_count = message[50] as usize;
        let header_len = 16 + 1 + APP_DOMAIN_LEN + 1 + 1 + (signer_count * PUBKEY_LEN) + 2;
        if signer_count >= 1 && message.len() > header_len {
            let embedded_len =
                u16::from_le_bytes([message[header_len - 2], message[header_len - 1]]) as usize;
            if embedded_len == message.len() - header_len {
                return Ok(message);
            }
        }
    }

    if message.len() > MAX_BODY_LEN {
        return Err(format!(
            "Off-chain message exceeds maximum length of {MAX_BODY_LEN} bytes"
        ));
    }

    let pubkey_bytes: [u8; PUBKEY_LEN] = if let Some(pk) = signer_pubkey {
        pk.as_slice()
            .try_into()
            .map_err(|_| "Invalid signer_pubkey: expected 32 bytes".to_string())?
    } else if let Some(addr_str) = signer_address {
        let addr = zilpay::proto::address::Address::from_solana_address(&addr_str)
            .map_err(|e| e.to_string())?;
        addr.addr_bytes()
            .try_into()
            .map_err(|_| "Invalid Solana address bytes: expected 32 bytes".to_string())?
    } else {
        return Err(
            "Signer 32-byte public key or Base58 address is required for Solana off-chain message header"
                .to_string(),
        );
    };

    // Match LedgerHQ/app-solana libsol/string_utils.c `is_data_ascii`:
    // printable ASCII (0x20..=0x7e) plus line feed '\n' (0x0a).
    let is_ascii = message
        .iter()
        .all(|&b| (0x20..=0x7e).contains(&b) || b == 0x0a);

    // In LedgerHQ/app-solana handle_sign_offchain_message.c:
    // V0 header.format must be 0 (RestrictedAscii) or 1 (LimitedUtf8); header.format > 1 returns 0x6a81.
    let format_byte: u8 = if is_ascii { 0 } else { 1 };

    let len_bytes = (message.len() as u16).to_le_bytes();
    let mut out = Vec::with_capacity(V0_HEADER_LEN + message.len());
    out.extend_from_slice(SIGNING_DOMAIN); // 16 bytes (0..16)
    out.push(0u8); // header version 0 (16)
    out.extend_from_slice(&[0u8; APP_DOMAIN_LEN]); // application domain (17..49)
    out.push(format_byte); // message format 0 or 1 (49)
    out.push(1u8); // signer count = 1 (50)
    out.extend_from_slice(&pubkey_bytes); // signer pubkey 32 bytes (51..83)
    out.extend_from_slice(&len_bytes); // message length u16 LE (83..85)
    out.extend_from_slice(&message); // message body (85..)

    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ledger_solana_pubkey_to_address() {
        let rt = zilpay::tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let pk_hex = "4d65a10662b9759d62bb59048366705454654cf4f9b4b3525cf314429e46c691";
            let pk_bytes = zilpay::alloy::hex::decode(pk_hex).unwrap();
            let addr = ledger_solana_pubkey_to_address(pk_bytes).await.unwrap();
            assert!(!addr.is_empty());
            assert!(addr.len() >= 32 && addr.len() <= 44);

            let zero_pk = vec![0u8; 32];
            let zero_addr = ledger_solana_pubkey_to_address(zero_pk).await.unwrap();
            assert_eq!(zero_addr, "11111111111111111111111111111111");

            let invalid = ledger_solana_pubkey_to_address(vec![1, 2, 3]).await;
            assert!(invalid.is_err());
        });
    }

    #[test]
    fn test_ledger_solana_prepare_offchain_message_v0_85_byte_header() {
        let rt = zilpay::tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async {
            let pk_hex = "4d65a10662b9759d62bb59048366705454654cf4f9b4b3525cf314429e46c691";
            let pk_bytes = zilpay::alloy::hex::decode(pk_hex).unwrap();
            let addr = ledger_solana_pubkey_to_address(pk_bytes.clone()).await.unwrap();

            let raw_msg = b"Long Off-Chain Test Message.".to_vec();
            let encoded = ledger_solana_prepare_offchain_message(
                raw_msg.clone(),
                Some(pk_bytes.clone()),
                None,
            )
            .await
            .unwrap();

            assert_eq!(encoded.len(), 85 + raw_msg.len());
            assert_eq!(&encoded[0..16], b"\xffsolana offchain");
            assert_eq!(encoded[16], 0); // version 0
            assert_eq!(&encoded[17..49], &[0u8; 32]); // application domain
            assert_eq!(encoded[49], 0); // format 0 (ASCII)
            assert_eq!(encoded[50], 1); // 1 signer
            assert_eq!(&encoded[51..83], pk_bytes.as_slice()); // signer pubkey
            assert_eq!(u16::from_le_bytes([encoded[83], encoded[84]]) as usize, raw_msg.len());
            assert_eq!(&encoded[85..], raw_msg.as_slice());

            // Encoding via signer_address produces identical bytes.
            let encoded_by_addr = ledger_solana_prepare_offchain_message(
                raw_msg.clone(),
                None,
                Some(addr),
            )
            .await
            .unwrap();
            assert_eq!(encoded_by_addr, encoded);

            // Idempotent when already formatted with 85-byte V0 header.
            let re_encoded = ledger_solana_prepare_offchain_message(encoded.clone(), None, None)
                .await
                .unwrap();
            assert_eq!(re_encoded, encoded);

            // UTF-8 non-ASCII message uses format 1 (Limited UTF-8).
            let utf8_msg = "Привет Solana".as_bytes().to_vec();
            let utf8_encoded = ledger_solana_prepare_offchain_message(
                utf8_msg.clone(),
                Some(pk_bytes),
                None,
            )
            .await
            .unwrap();
            assert_eq!(utf8_encoded[49], 1);
            assert_eq!(
                u16::from_le_bytes([utf8_encoded[83], utf8_encoded[84]]) as usize,
                utf8_msg.len()
            );
        });
    }
}


