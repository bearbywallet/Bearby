# Research: Uniswap Universal Router & Trading API — Reverts, Permit2, Deadlines

## Summary

The `execute(bytes,bytes[],uint256)` call on the Universal Router most commonly reverts due to expired deadlines (`TransactionTooOld`), insufficient Permit2 allowances (missing or revoked off-chain signatures), slippage failures (`TooLittleReceived`), or malformed command encoding. Permit2's PERMIT2_PERMIT command works entirely with off-chain EIP-712 signatures — no prior on-chain `approve()` is needed. The Uniswap Trading API expects only a Permit2 signature (not an on-chain approve), with `sigDeadline` and the `execute()` deadline serving different but related roles: the former controls how long the permit signature is valid, while the latter bounds the overall transaction validity window.

---

## Findings

### 1. Common Reasons for `execute(bytes,bytes[],uint256)` to Revert On-Chain

1. **Expired Deadline — `TransactionTooOld`**  
   The `deadline` parameter (third argument to `execute()`) is a Unix timestamp. If `block.timestamp > deadline`, the entire transaction reverts with `TransactionTooOld`. This is the most common revert in production, especially when users sign a quote and delay submission, or when mempool congestion causes delayed inclusion. [Source: Universal Router contract — deadline check at the top of `execute()`]

2. **Slippage Exceeded — `TooLittleReceived`**  
   Swaps using V2 or V3 commands include `amountOutMin` parameters. If on-chain execution yields fewer output tokens than specified, the swap reverts. This often happens when a quote's output amount degrades between the time of quoting and block inclusion. [Source: Uniswap Universal Router — V2_SWAP_EXACT_IN / V3_SWAP_EXACT_IN command handlers]

3. **Insufficient Permit2 Allowance / Signature Failure**  
   The PERMIT2_PERMIT command calls `Permit2.permit()`. If the EIP-712 signature is invalid, expired (`sigDeadline` passed), or the wrong token/amount/spender was signed, Permit2 reverts. Common pitfalls: signing with the wrong chain ID, using a stale nonce, or mis-encoding the `permitBatch` vs single `permit` call. [Source: Permit2 contract — `permit()` and `permitTransferFrom()`]

4. **Insufficient Token Balance or Allowance**  
   Even with a valid Permit2 signature, the user must hold sufficient tokens for the swap amount. If the user transferred tokens out between signing and execution, the transfer from Permit2 fails with a standard ERC-20 revert (e.g., `transfer amount exceeds balance`). [Source: Permit2 — `transferFrom()`]

5. **Malformed Command Bytes — `InvalidCommandType`**  
   The first byte of each command in the `commands` array encodes the command type (0x00 through 0x1F+). Unknown command bytes or incorrectly encoded inputs (wrong offsets/lengths in the ABI-encoded `inputs` array) cause reverts. This typically affects integrators constructing commands manually rather than using the Trading API's encoded calldata. [Source: Universal Router — `execute()` command dispatcher]

6. **ETH/WETH Mismatch**  
   Commands like `UNWRAP_WETH` or `WRAP_ETH` can revert if the router holds insufficient WETH to unwrap, or if `msg.value` doesn't match the ETH being wrapped. The Trading API's `/swap` response includes these commands when the output is ETH. [Source: Universal Router — PAYMENT_COMMANDS]

7. **Re-entrancy or Pair Not Found**  
   V2 swaps revert if the pair doesn't exist (zero reserves). V3 swaps revert if the pool is not initialized or has zero liquidity for the given tick range. [Source: Uniswap V2/V3 core contracts]

---

### 2. How PERMIT2_PERMIT Works — No Prior On-Chain Approve Required

The PERMIT2_PERMIT command (command byte `0x0A`) works **entirely off-chain** via EIP-712 typed structured signatures. Here's the flow:

1. **User signs an EIP-712 message** off-chain containing:
   - `token`: the ERC-20 token address
   - `amount`: the maximum amount to permit (typically `type(uint160).max` for "infinite" approval)
   - `nonce`: a Permit2-scoped nonce (different from ERC-20 nonces)
   - `deadline` (sigDeadline): when this signature expires

2. **The signature is submitted on-chain** via the Universal Router's PERMIT2_PERMIT command, which decodes `(uint256 amount, uint256 nonce, uint256 sigDeadline, bytes signature)` and calls `Permit2.permit(msg.sender, token, amount, nonce, sigDeadline, signature)`.

3. **Permit2 stores the allowance** in its own mapping — no ERC-20 `approve()` call is ever made to the token contract. The user never needs to call `token.approve()`.

4. **On subsequent transfers**, the Universal Router uses Permit2's `transferFrom()` which checks the internal Permit2 allowance mapping, not the ERC-20 allowance.

**Key insight**: The entire flow uses off-chain signatures. The only on-chain transaction is the `execute()` call itself which bundles the permit + the swap atomically. This is what enables "gasless approvals" — no separate `approve()` transaction. [Source: Permit2 smart contract — `permit()`, `allowance()`, and `transferFrom()`; Uniswap Universal Router — PERMIT2_PERMIT handler]

**Caveat**: If a user has *already* done a traditional `token.approve(universalRouter)` (ERC-20 approve), the Universal Router can also use V2_SWAP_EXACT_IN or V3_SWAP_EXACT_IN without PERMIT2_PERMIT, but the Trading API's recommended path always uses Permit2 for gas efficiency.

---

### 3. Correct Way to Use Permit2 with the Uniswap Trading API

**You should only use the Permit2 signature. Do NOT do a separate on-chain `approve()`.**

The canonical flow from the Uniswap Trading API docs:

1. **POST `/quote`** — get a quote with `swapType`, `amount`, `tokenIn`, `tokenOut`, etc.
2. **Check `slippageTolerance` and `deadline`** — these are returned in the quote response.
3. **POST `/swap`** with the quote as a parameter. The response includes:
   - `data`: the fully-encoded calldata for the Universal Router (includes PERMIT2_PERMIT command)
   - `router`: the Universal Router address
   - `value`: ETH to send
   - `permitData`: an object containing the typed data the user must sign via EIP-712
4. **Sign `permitData`** using `eth_signTypedData_v4`. This is the Permit2 signature.
5. **Submit the transaction**: call `UniversalRouter.execute(data.commands, data.inputs, deadline)` with the Permit2 signature embedded in the calldata.

**Why you should NOT do both:**
- Doing an on-chain `approve()` AND a Permit2 signature is redundant and wastes gas. The Permit2 `permit()` call already authorizes the transfer.
- If you do an on-chain `approve()` to the Universal Router directly (ERC-20 approve), the PERMIT2_PERMIT command in the calldata would still try to use Permit2's transfer path, which checks Permit2's allowance — not the ERC-20 allowance. These are separate allowance systems.
- If you want to bypass Permit2 entirely, you'd need to construct your own calldata without PERMIT2_PERMIT and use V2_SWAP_EXACT_IN/V3_SWAP_EXACT_IN directly — but the Trading API's `/swap` endpoint always includes PERMIT2_PERMIT when returning `permitData`.

**The one exception**: If the user has previously given infinite Permit2 allowance (via a prior signature), the API may omit `permitData` from the response, meaning no new signature is needed. In that case, the existing Permit2 allowance is reused. [Source: Uniswap Trading API documentation — `/quote` and `/swap` endpoints; Uniswap Permit2 spec]

---

### 4. Typical Deadline from `/quote` and What Happens on Expiry

**Typical deadline**: The `/quote` endpoint typically sets a deadline of **30 minutes** from the time the quote is generated (i.e., `Math.floor(Date.now() / 1000) + 1800`). This is the `deadline` field returned in both the `/quote` response and echoed in the `/swap` response's `permitData`.

**What happens when it expires:**

- **Before submission**: If the deadline has passed but you haven't submitted yet, submitting the transaction will cause the Universal Router to revert with `TransactionTooOld`. The quote is effectively stale.
- **During mempool pending**: If your transaction is pending in the mempool and the deadline passes before inclusion, the next block builder that tries to include it will see the revert. The transaction fails and you lose gas.
- **Quote staleness**: Even if the deadline hasn't passed, the quote's output amount may degrade due to market movement. The `slippageTolerance` parameter (default typically 0.5% or user-configured) protects against this.

**Best practice**: Always get a fresh quote immediately before submitting a swap. If the user takes more than a minute between quote and submission, re-fetch the quote. [Source: Uniswap Trading API documentation — `/quote` response schema; Universal Router — `TransactionTooOld` error]

---

### 5. Relationship Between `sigDeadline` (in permitData) and `deadline` (in execute())

These are two separate deadlines that serve different purposes and operate at different layers:

| Parameter | Where It Lives | What It Controls | Set By |
|-----------|---------------|------------------|--------|
| `sigDeadline` | Inside the Permit2 EIP-712 typed data (`permitData`) | How long the Permit2 *off-chain signature* is valid | The Trading API (typically matches the quote deadline) |
| `deadline` | Third argument to `execute(bytes,bytes[],uint256)` | How long the entire *on-chain transaction* is valid | The caller/dApp |

**Detailed relationship:**

1. **`sigDeadline`** is embedded in the Permit2 signature payload. When `Permit2.permit()` is called on-chain, it checks `block.timestamp <= sigDeadline`. If the signature has expired, the permit reverts *before* the swap even starts. This means the signature can expire independently of the transaction.

2. **`deadline`** (the execute argument) is checked at the very top of `execute()`. If `block.timestamp > deadline`, the entire call reverts immediately — no commands are processed.

3. **They should be aligned**. The Trading API typically sets `sigDeadline` equal to the quote's `deadline`. If you set a custom `deadline` in `execute()` that's *later* than `sigDeadline`, the permit could expire while the transaction is still valid — causing a revert during the PERMIT2_PERMIT command rather than the cleaner top-level `TransactionTooOld` revert.

4. **Recommended approach**: Use the same value for both. Take the `deadline` from the `/quote` or `/swap` response and pass it as the third argument to `execute()`. Don't use a custom, longer deadline.

**Example from Trading API flow:**
```javascript
// /swap response
{
  "permitData": {
    "domain": { ... },
    "message": {
      "sigDeadline": "1717286400",  // Permit2 signature expiry
      ...
    }
  },
  "deadline": "1717286400"  // Transaction deadline
}

// When submitting:
const deadline = swapResponse.deadline; // Use the same value
router.execute(commands, inputs, deadline);
```

If you use a different (longer) deadline for `execute()`, and `block.timestamp` falls between `sigDeadline` and `deadline`, the PERMIT2_PERMIT command will revert inside the execute call, giving a less clear error. [Source: Permit2 contract — `permit()` deadline check; Universal Router — `execute()` deadline check; Uniswap Trading API — permitData schema]

---

## Sources

- **Kept**: Universal Router smart contract (Permit2 integration, command dispatcher, deadline logic) — primary source for revert reasons and execute() mechanics
- **Kept**: Permit2 smart contract (permit(), transferFrom(), allowance()) — primary source for signature-based permit flow and sigDeadline semantics
- **Kept**: Uniswap Trading API documentation (trade-api.gateway.uniswap.org) — canonical source for /quote and /swap endpoint behavior, permitData schema
- **Dropped**: Third-party blog posts and tutorials — secondary commentary; contract code and official API docs are authoritative

## Gaps

1. **Exact default deadline value**: The Trading API docs mention "30 minutes" as typical but the exact value may vary by chain. Suggested: test `/quote` on the target chain and inspect the `deadline` field directly.
2. **Nonce management in Permit2**: The Trading API auto-handles nonces, but integrators building custom flows need to track Permit2 nonces per (owner, token, spender) tuple. The API's `/swap` response includes the correct nonce.
3. **Error decoding**: When `execute()` reverts, the revert reason is often a low-level Permit2 or pool error. Tools like Tenderly or `eth_call` tracing are needed to pinpoint the exact failing command within the multicall. The Universal Router itself does not bubble up detailed error enums beyond what the underlying contracts provide.
4. **ETH-denominated quotes**: The Trading API's behavior with native ETH (unwrap vs. direct ETH output) warrants further testing to confirm command encoding.
