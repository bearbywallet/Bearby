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

const KeystoreDomain = createDomain();
const _wallet = new WalletControler();
const initalState = {
  wallet: _wallet
};
const store = KeystoreDomain.store(initalState);

export default {
  store
};
