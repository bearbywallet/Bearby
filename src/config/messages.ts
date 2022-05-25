/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
const app = 'zil-pay';

export const Messages = {
  init: `@/${app}/injected-get-wallet-data`,
  block: `@/${app}/new-block-created`,
  signResult: `@/${app}/response-tx-result`,
  signTx: `@/${app}/request-to-sign-tx`,
  signMessage: `@/${app}/request-to-sign-message`,
  signMessageRes: `@/${app}/response-sign-message`,
  appConnect: `@/${app}/request-to-connect-dapp`,
  resConnect: `@/${app}/response-dapp-connect`,
  reqProxy: `@/${app}/request-through-content`,
  resProxy: `@/${app}/response-from-content`,
  reqDisconnect: `@/${app}/request-to-disconnect-dapp`
};
