# Remove all WalletConnect code — Bearby + bearby-core

Verified facts driving this plan: WC is a self-contained hand-written Rust SDK behind flutter_rust_bridge; every uncommitted hunk on this branch is WC-feature work; the in-app dApp browser (`lib/web3/`, `parse_tron_transaction`, shared sign modals, `manage_connections` legacy list) predates the branch on master and is **kept**. Platform manifests have no `wc:` scheme; pubspec has zero WC-only packages; l10n keys pre-exist on master.

## A. Bearby — Rust (delete WC-only code)
1. Delete `rust/src/api/walletconnect.rs` and the whole `rust/src/models/walletconnect/` dir (mod, engine, ffi, relay, relay_auth, rpc, session, store, pairing, crypto, error; `sign.rs` already deleted in working tree).
2. `rust/src/api/mod.rs`: remove `pub mod walletconnect;`; `rust/src/models/mod.rs`: same.
3. `rust/src/api/transaction.rs`: remove WC-only Solana helpers (`solana_tx_message_hex`, `solana_tx_fee_payer`, `solana_attach_signature`, private `decode_raw_tx`, ~lines 396–452), `tron_signed_tx_to_wc_json` (~729–755), and dead `tron_transaction_to_json` (zero callers). **Keep** `parse_tron_transaction` (used by `lib/web3/tron_web3.dart`) and `update_tx_with_params` broadcast logic (used by the dApp browser); reword its WC comment to "dApp sign-only requests".
4. `rust/src/api/utils.rs`: revert the uncommitted `hex_to_base58`/`base58_to_hex` additions (unused outside the WC service).
5. Cargo.toml untouched — all deps are shared; Cargo.lock refreshes on build.

## B. Bearby — Dart (delete + unwind call sites)
6. Delete: `lib/services/walletconnect_service.dart`, `lib/config/walletconnect.dart` (hardcoded projectId; only imported by the service), untracked `lib/components/connected_dapps_badge.dart` and `lib/utils/base58.dart`.
7. Strip WC hooks from shared files:
   - `lib/app.dart` — import + `navigatorKey` assignment.
   - `lib/state/app_state.dart` — import, `_notifyWalletConnectAccountChanged`, `_wcCaip2`, `_wcNamespaceForSlip44`, call in `updateSelectedAccount` (keep everything else).
   - `lib/pages/login_page.dart` — import + `WalletConnectService.instance.start()`.
   - `lib/pages/home_page.dart` — import + wc-URI branch in `_handleQrScanResult` (rest of QR flow stays).
   - `lib/pages/network.dart`, `lib/modals/swich_chain_modal.dart` — import + `notifyActiveNetwork` call.
   - `lib/services/deep_link_service.dart` — import + `wc` scheme branch (zilpay:/bitcoin:/etc. handling stays).
   - `lib/components/wallet_header.dart` — badge import + `ConnectedDappsBadge()` (the 2 uncommitted hunks).
   - `lib/modals/manage_connections.dart` — remove WC session list (`_wcSessions`, `_loadWcSessions`, `_disconnectWc`, filtered UI, wc imports); restore the legacy dApp-connection modal (master version is the baseline). Callers on master (`lib/pages/wallet.dart`) keep working.

## C. Regenerate FRB bindings
8. Run `flutter_rust_bridge_codegen generate` — rebuilds `rust/src/frb_generated.rs`, `lib/src/rust/frb_generated{,.io,.web}.dart` and auto-deletes `lib/src/rust/api/walletconnect.dart` + `lib/src/rust/models/walletconnect/*`. No hand-editing of generated files.

## D. bearby-core (user opted in)
9. In `/Users/hicaru/projects/bearby/bearby-core`: remove `x25519-dalek`, `chacha20poly1305`, `hkdf`, `tokio-tungstenite` from `Cargo.toml` (workspace deps + versions) and `zilpay/Cargo.toml`, and remove the 4 `pub use` re-exports in `zilpay/src/lib.rs` (lines 5, 8, 25, 27). Verified: zero code usages of these crates in bearby-core; remaining "WalletConnect" mentions there are comments only. Run `cargo check` there.

## E. Verification
10. `cargo check` (Bearby rust/) — clean compile.
11. `flutter analyze` — no WC references.
12. `grep -ri walletconnect lib/ rust/src` — expect zero hits.
13. `flutter test` if quick; report results.

No commits — changes stay in the working tree for your review.