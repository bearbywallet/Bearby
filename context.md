# Code Context

## Files Retrieved
1. `rust/src/models/exchange/uniswap.rs` (entire file, 474 lines) — Core Uniswap Trading API integration: `/quote`, `/swap`, Permit2 handling, tx construction
2. `rust/src/api/exchange.rs` (entire file, 660 lines) — Orchestration layer: software-wallet swap, Ledger step-by-step, fee application, approval checking
3. `bearby-core/background/src/bg_tx.rs` (lines 24–150) — `update_tx_from_params`: how fees are applied to EVM transactions
4. `bearby-core/network/src/evm/mod.rs` (lines 89–215) — `evm_estimate_params_batch`: how base params are estimated from RPC
5. `rust/src/models/exchange/mod.rs` (lines 52–84) — `ExchangeTxDisplay`, `ExchangeQuoteInfo` structs
6. `rust/src/api/transaction.rs` (lines 47–120) — `unlock_seed`, `sign_and_broadcast_one` — signing entry points
7. `bearby-core/proto/src/tx.rs` (line 32) — `ETHTransactionRequest = alloy::rpc::types::eth::request::TransactionRequest`

---

## 1. How the Swap Deadline Flows

**Path**: `/quote` → Permit2 `permitData` → serialized into `quote_blob` → `/swap` → on-chain

```
/quote response:
  permitData: {
    domain: { name, chainId, verifyingContract },
    types: { PermitSingle: [{ details: "PermitDetails" }, { spender: "address" }, { sigDeadline: "uint256" }], ... },
    values: { spender, sigDeadline, details: { token, amount, expiration, nonce } }
  }
```

- `prepare_uniswap_swap` calls `/quote`, stores the full response (including `permitData` with `sigDeadline` and `expiration`) into `quote_blob` as a JSON string (**uniswap.rs:336**).
- `permit_to_typed_data` (uniswap.rs:156–200) converts `permitData` to EIP-712 format for signing. The deadline is embedded in the typed data `message.values.sigDeadline`.
- `finalize_uniswap_swap` deserializes `quote_blob`, calls `build_swap_body` which re-attaches the **original** `permitData` + `signature` (**uniswap.rs:209–226**).
- The `/swap` endpoint receives the original quote body with `permitData` and `signature`, uses them to build the Universal Router `execute` calldata that encodes the `PERMIT2_PERMIT` command with the deadline.

**Key detail**: The deadline is **set by the Trading API in the `/quote` response**, not by the client. The deadline is both signed (part of EIP-712 `PermitSingle.sigDeadline`) and embedded in the calldata. If the tx is not mined before `sigDeadline`, `PERMIT2_PERMIT` reverts.

---

## 2. The Approve + PERMIT2_PERMIT Double Authorization Pattern

Two separate on-chain authorizations at sequential nonces:

### Software wallet path (`execute_exchange_swap`, **exchange.rs:304–387**):
```
nonce N:   approve(ERC20 → Permit2)           — standard ERC-20 approve
           ↓ broadcast, wait in mempool
nonce N+1: UniversalRouter.execute(
             PERMIT2_PERMIT,                   — Permit2.permit() using signed PermitSingle
             V3_SWAP_EXACT_IN,                 — actual swap
             UNWRAP_WETH                       — unwrap output
           )
```

- `uniswap_check_approval` (**uniswap.rs:398–429**) calls Trading API `/check_approval`, returns an unsigned `approve` tx if allowance < amount.
- The approve tx targets the Permit2 contract (`0x000000000022D473030F116dDEE9F6B43aC78BA3`) or a bridge spender for cross-chain.
- The swap tx is a single Universal Router `execute(bytes,bytes[],uint256)` call with commands `0x0a000c`:
  - `0x0a` = PERMIT2_PERMIT — calls Permit2 with the signed permit data
  - `0x00` = V3_SWAP_EXACT_IN — executes the swap via Uniswap V3
  - `0x0c` = UNWRAP_WETH — unwraps WETH to native ETH

### Why both?
The approve is a one-time allowance grant. The PERMIT2_PERMIT is a gas-efficient per-swap authorization that doesn't require a separate transaction. Both are needed because:
1. Permit2 needs the ERC-20 allowance to pull tokens
2. The PERMIT2_PERMIT command validates the EIP-712 signature (deadline, nonce, amount) to authorize the specific transfer

### Ledger path (`check_exchange_approval` → `prepare_exchange_swap` → `finalize_exchange_swap`):
Same pattern but split across three step-by-step calls (**exchange.rs:416–565**), each returning a tx for the device to sign.

---

## 3. The `apply_fast_fees` Function — Does It Override API Gas?

**It correctly preserves the API gas limit** — with one critical edge case.

```rust
// exchange.rs:281–293
fn apply_fast_fees(tx: &mut TransactionRequest, base: &RequiredTxParams, nonce: u64) {
    let api_gas = match tx {
        TransactionRequest::Ethereum((eth, _)) => eth.gas,  // save API gasLimit
        _ => None,
    };
    let mut params = base.clone();
    params.nonce = nonce;
    if let Some(g) = api_gas {
        params.tx_estimate_gas = U256::from(g);  // ← overrides with API value
    }
    update_tx_from_params(tx, params, U256::ZERO)?;
}
```

Inside `update_tx_from_params` (**bg_tx.rs:45**):
```rust
eth_tx.gas = Some(params.tx_estimate_gas.try_into()...);
```

So `eth_tx.gas` is always set from `params.tx_estimate_gas`. Since `apply_fast_fees` puts the API gas there, **the API gas survives**.

### Edge case: API missing `gasLimit`
If `/swap` or `/check_approval` doesn't return `gasLimit`:
- `eth_tx.gas` is `None` from `json_obj_to_eth_tx`
- `api_gas` is `None` → the `if let Some(g)` branch is skipped
- `params.tx_estimate_gas` stays at the value from `estimate_fast_params`

`estimate_fast_params` (**exchange.rs:243–264**) estimates gas on a **default empty tx** (`ETHTransactionRequest::default()`). The `evm_estimate_params_batch` (`eth_estimateGas` on an empty tx) returns ~21000 or 53000 (**mod.rs:153–158**):
```rust
let tx_estimate_gas_response = ...
    .unwrap_or(U256::from(21000));
```

**If the API ever omits `gasLimit`, the swap would get gas=21000 and fail with out-of-gas.** The API should always return `gasLimit`, but there's no defensive fallback.

### Other fee details
- `estimate_fast_params` sets `params.current = params.fast` — so both approve and swap use FAST priority fee tier.
- `balance: U256::ZERO` is passed to `update_tx_from_params` — this correctly prevents native-transfer value adjustment for swap txs.
- The EIP-1559 `max_fee_per_gas` is computed as `params.current / gas_limit` (**bg_tx.rs:80**). For large gas limits (275k+), this division can drop below `priority_fee`, but the code enforces the invariant at **bg_tx.rs:87–88**:
  ```rust
  let max_fee_per_gas = std::cmp::max(max_fee_per_gas, priority_fee);
  ```

---

## 4. `build_swap_body` — Does It Correctly Attach permitData + Signature?

**Yes, with one questionable choice.** (**uniswap.rs:209–226**)

```rust
fn build_swap_body(quote_resp: &Value, signature: Option<&str>) -> Result<Value, String> {
    let mut obj = quote_resp.as_object()?.clone();
    let permit = obj.remove("permitData");      // remove original
    obj.remove("permitTransaction");             // remove optional permit tx
    obj.remove("requestId");                     // ← removed!

    if let (Some(sig), Some(pd)) = (signature, permit) {
        if !pd.is_null() {                       // guard against JSON null
            obj.insert("signature".to_string(), Value::String(sig.to_owned()));
            obj.insert("permitData".to_string(), pd);  // re-attach original
        }
    }
    Ok(Value::Object(obj))
}
```

**What it does correctly:**
- Strips `permitData` then conditionally re-attaches it — both `permitData` and `signature` are either both present or both absent
- The `!pd.is_null()` check correctly handles `permitData: null` (native input)
- Strips `permitTransaction` (separate permit tx for some routings, not needed with our inline PERMIT2_PERMIT)
- Re-attaches the **original** `permitData` in the Trading API's format (`{domain, types, values}`), which is what `/swap` expects

**What is questionable:**
- **`requestId` is stripped.** The Trading API might use `requestId` for quote freshness validation on `/swap`. If the API expects it, the `/swap` call could be rejected. However, the code intentionally strips it (confirmed by the test at **uniswap.rs:460**), suggesting the API doesn't require it.

**The signature itself** is produced by `sign_typed_data_eip712` (**transaction.rs:385–417**), which:
1. Calls `prepare_eip712_message` (parses the JSON into `TypedData`)
2. Calls `keypair.sign_typed_data_eip712(typed_data)` which uses alloy's `eip712_signing_hash()` + `sign_hash()`
3. Returns the signature as a `0x`-prefixed hex string

The signature is then passed to `build_swap_body` as `&str` and inserted into the `/swap` request body as `"signature": "0x..."`.

---

## 5. Potential Race Conditions in the Software Wallet Path

The full flow in `execute_exchange_swap` (**exchange.rs:304–387**):

```
1. unlock_seed
2. estimate_fast_params → gets nonce N (eth_getTransactionCount("latest"))
3. resolve_swap_signer
4. uniswap_check_approval → Trading API /check_approval
5. [if needed] broadcast approve tx with nonce N
   nonce += 1
6. prepare_uniswap_swap → NEW /quote call (re-quote after approve)
7. [if permitData] sign Permit2 EIP-712 with seed
8. finalize_uniswap_swap → /swap with quote_blob + signature
9. broadcast swap tx with nonce N+1
```

### Race Condition A: Re-quote After Approve Broadcast (Intentional, but risky)
After broadcasting the approve (step 5), `prepare_uniswap_swap` calls `/quote` again (step 6). This gets a **fresh quote with potentially different routing, price, and Permit2 data** (different `sigDeadline`, different `nonce` in `PermitDetails`). The original pre-approve quote is discarded. This is intentional: the approve might take time to mine, and by the time it's mined, the original quote could be stale.

**Risk**: If the approve tx is still pending, the `/quote` API doesn't know about it. The quote assumes zero allowance (since approve isn't mined yet). But this doesn't affect the quote itself — the Trading API routes based on liquidity, not user allowance. The allowance check happens on-chain.

### Race Condition B: Approve Not Mined Before Swap
Both txs use sequential nonces (N, N+1). In EVM, nonce N+1 cannot execute before nonce N. So the swap **cannot execute before the approve**. However:
- If the approve **reverts** on-chain (e.g., token has transfer restrictions), the swap at nonce N+1 still executes but the PERMIT2_PERMIT will revert because Permit2 lacks allowance.
- The approve could get stuck in the mempool (low gas), causing both txs to fail.

### Race Condition C: Permit Deadline Expiration
Between signing the Permit2 EIP-712 (step 7) and the swap tx being mined (step 9+), the `sigDeadline` in the `PermitSingle` could expire. This is especially risky if:
- Gas price spikes after fee estimation (step 2), causing slow mining
- The chain is congested
- The `sigDeadline` is set aggressively by the Trading API

**The fee is estimated once at step 2, before the approve/quote/sign flow.** If gas spikes by the time the swap is broadcast (step 9), the tx could be underpriced and sit in the mempool past the deadline.

### Race Condition D: Fee Estimation Staleness
`estimate_fast_params` (step 2) uses `eth_feeHistory` + `eth_gasPrice` + `eth_estimateGas` once. Both approve and swap use this same base. If gas prices spike during steps 3–8, both txs use stale fees. The swap is more vulnerable because it's broadcast last and has more complex calldata.

### Race Condition E: Concurrent Nonce Consumption
If the user has another pending tx from the same wallet (e.g., a transfer), the nonce N from step 2 could be consumed before step 5. The approve would then fail with "nonce too low". This is unlikely in normal usage but possible with concurrent app actions.

### Race Condition F: `/swap` API Quote Freshness
`build_swap_body` strips `requestId` from the quote. If the Trading API tracks quote freshness via `requestId`, the `/swap` call could be rejected. Without `requestId`, the API might just use the most recent valid quote or reject it. **This is the most suspicious part of the flow.**

---

## 6. Analysis of Failed Tx: `0xacc5ca13bae193e8ff2ad4f66a082c2882150a6622de4cfab6d9681edef3eed4`

**Commands**: `0x0a000c` = PERMIT2_PERMIT → V3_SWAP_EXACT_IN → UNWRAP_WETH

The transaction calls `UniversalRouter.execute(bytes,bytes[],uint256)` with three commands. The failure could be at any of these steps.

### Most Likely Failure: PERMIT2_PERMIT step

The PERMIT2_PERMIT command calls `Permit2.permit()` with the signed `PermitSingle` data. It can fail if:

1. **`sigDeadline` expired** — the block.timestamp exceeds the deadline in the permit. This is the most common cause if there's a delay between quote/sign and broadcast/mining.

2. **Permit2 allowance insufficient** — the `approve` tx gave allowance to Permit2, but:
   - The approve tx reverted or wasn't mined
   - The approve gave a lower amount than what PERMIT2_PERMIT tries to transfer
   - Fee-on-transfer tokens: approved amount ≠ transferable amount

3. **Signature mismatch** — possible causes:
   - The `permitData` from `/quote` has a different `PermitDetails.nonce` than what was signed
   - The signer address doesn't match `msg.sender` in the UniversalRouter context
   - **Critical**: `build_swap_body` re-attaches the **original** `permitData` from the quote, but the signature was produced from `permit_to_typed_data(permitData)`. If `permit_to_typed_data` alters the data (it injects `EIP712Domain` type), this is fine for signing. But the API expects the original format. If there's any mismatch between the signed data and what the API embeds in calldata, the PERMIT2_PERMIT reverts.

4. **Chain ID mismatch** — the `domain.chainId` in the permit must match the broadcast chain. Since `json_obj_to_eth_tx` sets `tx.chain_id` from the API response, and then `sign_and_broadcast_one` **overwrites** it with `chain.config.chain_id()` (**transaction.rs:93**), there could be a mismatch if the API returns a different chainId (e.g., for bridges). However, same-chain swaps should match.

### Second Possibility: V3_SWAP_EXACT_IN step

If PERMIT2_PERMIT succeeds but the swap fails:
- **Slippage exceeded** — the output amount is below the minimum due to price movement between quote and execution
- **Pool liquidity changed** — large trade between quote and execution

### Third: UNWRAP_WETH step

Only fails if the V3 swap output is less WETH than expected, or if the WETH contract has issues. Least likely.

### Recommendation
To diagnose: check the revert reason on Etherscan/Tenderly. The most actionable fix would be:
1. **Log the `sigDeadline` from the permit** before signing to verify it's far enough in the future
2. **Consider increasing `slippageTolerance`** (currently hardcoded to 0.5% at **uniswap.rs:131** — `f64::from(slippage_bps) / 100.0` where `slippage_bps=50`)
3. **Verify the approve tx succeeded** before re-quoting — the current flow broadcasts approve and immediately re-quotes without waiting for confirmation

---

## Architecture Summary

```
Dart UI
  │
  ├── execute_exchange_swap()  [software wallet — batch]
  │     ├── estimate_fast_params (RPC: eth_feeHistory + eth_gasPrice + eth_getTransactionCount)
  │     ├── uniswap_check_approval → /check_approval → approve tx
  │     ├── prepare_uniswap_swap → /quote → permitData → sign EIP-712
  │     └── finalize_uniswap_swap → /swap → calldata → broadcast
  │
  └── check_exchange_approval / prepare_exchange_swap / finalize_exchange_swap  [Ledger — step-by-step]
        └── Same sub-steps, caller sequences nonces and device prompts
```

Data flow:
```
/quote response → quote_blob (serialized JSON, includes permitData)
    ↓
permit_to_typed_data(permitData) → EIP-712 JSON → sign_typed_data_eip712 → signature
    ↓
build_swap_body(quote_blob, signature) → /swap request body
    ↓
/swap response.swap → json_obj_to_eth_tx → ETHTransactionRequest
    ↓
apply_fast_fees (preserves gasLimit, sets nonce, gas fees) → sign_and_broadcast_one → on-chain
```

---

## Start Here

Open `/Users/hicaru/projects/bearby/Bearby/rust/src/api/exchange.rs` at line 304 (`execute_exchange_swap`). Trace the full software wallet path and verify:
1. Whether the approve tx was actually mined before the swap re-quote
2. The `sigDeadline` value in the permit data from the re-quote
3. Whether `requestId` stripping in `build_swap_body` (**uniswap.rs:216**) causes `/swap` rejections
4. The gas parameters actually sent in the failed tx vs. what the API suggested
