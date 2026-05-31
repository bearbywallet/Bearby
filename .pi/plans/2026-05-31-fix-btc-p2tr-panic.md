---
title: "Fix PanicException: cannot convert slice of length 62 to Address"
status: draft
created: "2026-05-31T17:23:18.382Z"
type: fix
---

## Root Cause

`Address::to_alloy_addr()` in `proto/src/address.rs:110-111` uses `alloy::primitives::Address::from_slice(self.as_ref())` which **panics** if the slice is not exactly 20 bytes.

For `Address::Secp256k1Bitcoin`, `self.as_ref()` returns the UTF-8 encoded Bitcoin address string (e.g., a P2TR Bech32m address is 62 chars = 62 bytes). When any code path calls `to_alloy_addr()` on a Bitcoin address, it panics with "cannot convert a slice of length 62 to Address".

## Affected Code

### Primary — panic source:

**File:** `bearby-core/proto/src/address.rs` line 110-111
```rust
pub fn to_alloy_addr(&self) -> alloy::primitives::Address {
    alloy::primitives::Address::from_slice(self.as_ref())  // PANICS on Bitcoin addresses
}
```

### Callers of `to_alloy_addr()` (29 call sites across 8 files):

All callers assume the `Address` is Ethereum-compatible (`Secp256k1Keccak256` or `Secp256k1Tron`). These are safe under normal flow (type checks before calling), but a Bitcoin address leaking through would trigger the panic.

### Also at risk (safe for their variants but confirm):

- `Display` at line 406 — only matches `Secp256k1Keccak256({ [u8; 20] })` — safe
- `Debug` at line 424 — same — safe

## Fix Plan

### Phase 1: Make `to_alloy_addr()` safe

**File:** `bearby-core/proto/src/address.rs`

Change `to_alloy_addr()` to return `Result<alloy::primitives::Address, AddressError>` and use `try_from` instead of `from_slice`:

```rust
pub fn to_alloy_addr(&self) -> Result<alloy::primitives::Address, AddressError> {
    alloy::primitives::Address::try_from(self.as_ref())
        .map_err(|e| AddressError::InvalidETHAddress(e.to_string()))
}
```

Or alternatively, add a match to reject non-Ethereum address types:

```rust
pub fn to_alloy_addr(&self) -> Result<alloy::primitives::Address, AddressError> {
    match self {
        Address::Secp256k1Keccak256(bytes) => Ok(alloy::primitives::Address::from_slice(bytes)),
        Address::Secp256k1Tron(bytes) => Ok(alloy::primitives::Address::from_slice(bytes)),
        _ => Err(AddressError::InvalidAddressType),
    }
}
```

### Phase 2: Update all callers (29 sites)

Every caller of `to_alloy_addr()` must be updated to handle the `Result`. The changes are mechanical — wrap with `?` or `.map_err()`:

**Files to update:**
1. `background/src/bg_token.rs` (4 calls — closures inside `build_token_transfer`)
2. `network/src/evm/ft_parse.rs` (2 calls — `generate_transfer_input`, `build_eth_requests`)
3. `network/src/tron/mod.rs` (1 call)
4. `network/src/zil/zil_stake_evm.rs` (5+ calls)
5. `network/src/provider.rs` (8+ calls)
6. `proto/src/signature.rs` (2 calls)
7. `proto/src/tx.rs` (5+ calls)

### Phase 3: Add regression test

Add a test in `proto/src/address.rs` that verifies `to_alloy_addr()` returns `Err` for Bitcoin addresses instead of panicking.

### Verification

1. `cargo test` in `bearby-core` — all tests pass
2. `cargo build` in `bearby-core` — no compile errors
3. `flutter_rust_bridge_codegen generate` in Bearby — regenerates bindings
4. `flutter build` — app builds successfully
5. Manual test: create and send a Bitcoin P2TR transaction — no panic
