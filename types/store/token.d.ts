/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */

export type KeyValue = {
  [key: string]: string;
};

export interface Token {
  address: KeyValue;
  balance: KeyValue;
  totalSupply: KeyValue;
  decimals: string;
  default?: boolean;
  name: string;
  owner: string;
  symbol: string;
}
