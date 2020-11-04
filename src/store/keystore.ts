/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain } from 'effector';
import { WalletControler } from 'app/lib/controller';

const _wallet = new WalletControler();
const KeystoreDomain = createDomain();

export const toSync = KeystoreDomain
  .effect()
  .use(_wallet.sync);

const store = KeystoreDomain
  .store(_wallet)
  .on(toSync.done, () => _wallet);

export default {
  store,
  toSync
};
