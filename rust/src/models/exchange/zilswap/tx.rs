use std::str::FromStr;

use flutter_rust_bridge::frb;
use zilpay::alloy::primitives::U256;
use zilpay::proto::address::Address;
use zilpay::proto::tx::{TransactionMetadata, TransactionRequest};
use zilpay::proto::zil_tx::ZILTransactionRequest;
use zilpay::serde_json::{json, Value};

use super::addr::{strip_0x, with_0x_lower};
use super::math::{apply_bps_cut, SwapDirection};
use super::{ZilSwapConfig, APPROVAL_GAS, SWAP_GAS};
use crate::models::transactions::base_token::BaseTokenInfo;
use crate::models::transactions::request::TransactionRequestInfo;

fn u128_from_u256(value: U256, field: &str) -> Result<u128, String> {
    value
        .to_string()
        .parse::<u128>()
        .map_err(|_| format!("{field} exceeds Uint128"))
}

fn chain_id_u16(chain_id: u64) -> Result<u16, String> {
    u16::try_from(chain_id).map_err(|_| "chain_id exceeds u16".to_string())
}

fn param(vname: &str, value_type: &str, value: impl Into<Value>) -> Value {
    json!({
        "vname": vname,
        "type": value_type,
        "value": value.into(),
    })
}

fn scilla_data(tag: &str, params: Vec<Value>) -> Vec<u8> {
    json!({
        "_tag": tag,
        "params": params,
    })
    .to_string()
    .into_bytes()
}

fn scilla_tx(
    chain_id: u64,
    to_base16: &str,
    amount: U256,
    gas_limit: u64,
    tag: &str,
    params: Vec<Value>,
) -> Result<ZILTransactionRequest, String> {
    Ok(ZILTransactionRequest {
        chain_id: chain_id_u16(chain_id)?,
        nonce: 0,
        gas_price: 0,
        gas_limit,
        to_addr: Address::from_zil_base16(strip_0x(to_base16)).map_err(|e| e.to_string())?,
        amount: u128_from_u256(amount, "amount")?,
        code: Vec::with_capacity(0),
        data: scilla_data(tag, params),
    })
}

fn metadata(
    chain_hash: u64,
    title: Option<String>,
    info: Option<String>,
    icon: Option<String>,
    out_token: Option<BaseTokenInfo>,
) -> TransactionMetadata {
    TransactionMetadata {
        chain_hash,
        broadcast: true,
        title,
        info,
        icon,
        token_info: out_token.map(|token| {
            let value = U256::from_str(&token.value).unwrap_or(U256::ZERO);
            (value, token.decimals, token.symbol)
        }),
        ..Default::default()
    }
}

fn lift(
    tx: ZILTransactionRequest,
    metadata: TransactionMetadata,
) -> Result<TransactionRequestInfo, String> {
    TransactionRequest::Zilliqa((tx, metadata))
        .try_into()
        .map_err(|e: zilpay::errors::tx::TransactionErrors| e.to_string())
}

#[frb(ignore)]
pub struct SwapTxArgs<'a> {
    pub cfg: &'a ZilSwapConfig,
    pub direction: SwapDirection,
    pub chain_id: u64,
    pub chain_hash: u64,
    pub amount_in: U256,
    pub amount_out: U256,
    pub slippage_bps: u32,
    pub deadline_block: u64,
    pub account_key: &'a str,
    pub token_base16: &'a str,
    pub token_out_base16: &'a str,
    pub title: String,
    pub info: String,
    pub icon: String,
    pub out_token: Option<BaseTokenInfo>,
}

#[frb(ignore)]
pub fn build_swap_tx(args: SwapTxArgs<'_>) -> Result<TransactionRequestInfo, String> {
    let min_out = apply_bps_cut(args.amount_out, args.slippage_bps);
    // amount_out is the direction-aware net quote from net_quote():
    //   ZIL→Token: output_for(amount_in × 0.9) — exactly what core produces
    //   Token→ZIL: output_for(...) × 0.9 — exactly what user receives after AddFunds
    //   Token→Token: full two-hop output — no proxy in the path
    // min_out is the slippage haircut of that net amount. It's safe because it's
    // strictly below the on-chain achievable output for every direction.
    let recipient = with_0x_lower(args.account_key);
    let tx = match args.direction {
        SwapDirection::ZilToToken => scilla_tx(
            args.chain_id,
            args.cfg.proxy,
            args.amount_in,
            SWAP_GAS,
            "SwapExactZILForTokens",
            vec![
                param(
                    "token_address",
                    "ByStr20",
                    with_0x_lower(args.token_out_base16),
                ),
                param("min_token_amount", "Uint128", min_out.to_string()),
                param("deadline_block", "BNum", args.deadline_block.to_string()),
                param("recipient_address", "ByStr20", recipient.clone()),
            ],
        )?,
        SwapDirection::TokenToZil => scilla_tx(
            args.chain_id,
            args.cfg.core,
            U256::ZERO,
            SWAP_GAS,
            "SwapExactTokensForZIL",
            vec![
                param("token_address", "ByStr20", with_0x_lower(args.token_base16)),
                param("token_amount", "Uint128", args.amount_in.to_string()),
                param("min_zil_amount", "Uint128", min_out.to_string()),
                param("deadline_block", "BNum", args.deadline_block.to_string()),
                param(
                    "recipient_address",
                    "ByStr20",
                    with_0x_lower(args.cfg.proxy),
                ),
            ],
        )?,
        SwapDirection::TokenToTokens => scilla_tx(
            args.chain_id,
            args.cfg.core,
            U256::ZERO,
            SWAP_GAS,
            "SwapExactTokensForTokens",
            vec![
                param(
                    "token0_address",
                    "ByStr20",
                    with_0x_lower(args.token_base16),
                ),
                param(
                    "token1_address",
                    "ByStr20",
                    with_0x_lower(args.token_out_base16),
                ),
                param("token0_amount", "Uint128", args.amount_in.to_string()),
                param("min_token1_amount", "Uint128", min_out.to_string()),
                param("deadline_block", "BNum", args.deadline_block.to_string()),
                param("recipient_address", "ByStr20", recipient.clone()),
            ],
        )?,
    };

    lift(
        tx,
        metadata(
            args.chain_hash,
            Some(args.title),
            Some(args.info),
            Some(args.icon),
            args.out_token,
        ),
    )
}

#[frb(ignore)]
pub fn build_increase_allowance(
    chain_id: u64,
    chain_hash: u64,
    token_base16: &str,
    spender_base16: &str,
    amount: U256,
    title: String,
    icon: String,
) -> Result<TransactionRequestInfo, String> {
    let tx = scilla_tx(
        chain_id,
        token_base16,
        U256::ZERO,
        APPROVAL_GAS,
        "IncreaseAllowance",
        vec![
            param("spender", "ByStr20", with_0x_lower(spender_base16)),
            param("amount", "Uint128", amount.to_string()),
        ],
    )?;

    lift(
        tx,
        metadata(chain_hash, Some(title), None, Some(icon), None),
    )
}
