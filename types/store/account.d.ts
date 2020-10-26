/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */

import { AccountTypes } from 'src/config/account-type';

export interface Account {
  name: string;
  index: number;
  type: AccountTypes;
  nonce: number;
  base16: string;
  bech32: string;
  privKey?: string;
}
export interface AccountState {
  identities: Account[];
  selectedAddress: number;
}

export interface KeyPair {
  index: number,
  privateKey: string;
  publicKey: string;
}
