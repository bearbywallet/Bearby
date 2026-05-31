---
title: "Exchange confirm modal — loading lock, error, close + navigate"
status: draft
created: "2026-05-31T21:03:34.506Z"
type: fix
---

## Context

`lib/modals/exchange_confirm.dart` drives approve→permit→swap. Runtime log confirms the Rust
flow is correct end-to-end (`approving→approved→permit→swapping→done`, swap broadcast, `/swap`
response received). The remaining defects are **UI/modal-lifecycle only**:

1. Sheet is dismissible mid-execution (no `PopScope`) — user can swipe-down / tap-barrier / back
   while the batched tx is broadcasting (or Ledger mid-sign).
2. Error display already works (`GlassMessage` via `_error`) — keep, verify both paths reset
   `_loading=false`.
3. "Refresh history" → **decided: rely on history-page self-load**. `app_state` holds no history
   list; `history_page.dart` self-loads via `getHistory(walletIndex)` in `initState`, and the swap
   is already persisted in Rust (`sign_and_broadcast_one` → `HistoricalTransactionInfo`). So
   navigating to the history page already shows the new swap. No `app_state` change.
4. On success the modal does **not** pop — call site `onDone: () => context.go(AppRoutes.history)`
   has no `Navigator.pop()`, leaving the sheet mounted over the history route.

## Decisions (confirmed)
- History: rely on history-page self-load — no `app_state` history method, no call-site change.
- Lock: **block all dismissal** while `_loading` via `PopScope(canPop: !_loading)`.

## Reuse (DRY)
- Completion pattern from `stake_modal.dart:580-581`: `Navigator.of(context).pop();` then
  `context.go(AppRoutes.history)` after `await appState.syncData()`.
- `appState.syncData()` already invoked in both success paths — keep (refreshes balances).
- `GlassMessage`, `_error`, `_resetSteps`, `SwipeButton.disabled`, `SmartInput.disabled` — all
  already wired; do not duplicate.

## Scope
Single file: `lib/modals/exchange_confirm.dart`. **No** `app_state.dart` change, **no** call-site
change in `exchange_page.dart` (`onDone` still owns navigation; modal pops first).

## Change 1 — single completion helper (DRY both paths)
Add one private method; replaces the duplicated `syncData + onDone` tail in software `onDone` and the
Ledger success block:
```dart
/// Refresh balances, close the sheet, then hand navigation back to the opener.
Future<void> _completeAndExit(AppState appState) async {
  await appState.syncData();            // balances/book/connections (history self-loads on nav)
  if (!mounted) return;
  Navigator.of(context).pop();          // close the sheet (fixes "modal stays open")
  widget.onDone();                      // page context: context.go(AppRoutes.history)
}
```
- Software `onDone:` → `onDone: () => _completeAndExit(appState)` (drop inline `syncData`/`onDone`).
- Ledger success tail (currently `await appState.syncData(); if (mounted) widget.onDone();`) →
  `await _completeAndExit(appState);`. The trailing `finally { if (mounted) setState(_loading=false) }`
  stays safe — after pop, `mounted` is false so it no-ops.

## Change 2 — block all dismissal while loading
Wrap the top-level `Container` returned from `build()` in `PopScope`:
```dart
return PopScope(
  canPop: !_loading,                    // swipe-down / barrier-tap / back all no-op while executing
  child: Container( /* existing modal tree unchanged */ ),
);
```
- Keep `isDismissible: true` / `enableDrag: true` at `showModalBottomSheet` (barrier + drag both
  route through `Navigator.maybePop`, which honors `canPop`). Dismissal re-enables automatically on
  error/done because `_loading` flips back to `false`.
- No new imports (`PopScope`, `Navigator` from `material.dart`, already imported).

## Change 3 — verify error handling (no new code expected)
Confirm both failure paths set `_loading=false` so dismissal unlocks and `SwipeButton` re-enables:
- Software: `stream.listen(onError: …)` already `setState(_loading=false, _error=…)`. ✓
- Ledger: `catch` sets `_error`; `finally` sets `_loading=false`. ✓
Only touch if a gap is found during review.

## Non-goals
- No `app_state` history collection / `syncHistory()` (history-page self-load chosen).
- No Rust changes.
- No redesign of timeline/hero/meta (prior task).

## Verification
1. `flutter analyze lib/modals/exchange_confirm.dart` → no issues.
2. Run app, open Exchange, swipe to swap:
   - **During execution:** swipe-down, tap-outside, and back button do nothing; password input +
     swipe button disabled; timeline animates ◐→✓.
   - **On done:** sheet closes itself and lands on the History page; the new swap appears (page
     `getHistory` on navigation).
   - **On error (reject / failure):** `GlassMessage` shows the error, sheet becomes dismissible
     again, `SwipeButton` re-enables for retry.
   - Native (BNB→CAKE) single-step and ERC-20 approve+permit+swap both close + navigate correctly.
