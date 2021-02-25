/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
export enum WalletConnectTypes {
  Start = 'start-sync',
  EndSync = 'end-sync',
  SyncingData = 'syncing-data',
  SyncError = 'error-sync',
  SyncDone = 'sync-done'
}
