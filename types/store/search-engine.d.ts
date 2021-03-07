/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */

export interface SearchEngineType {
  name: string;
  query: string;
}

export interface SearchEngineStoreType {
  identities: SearchEngineType[];
  selected: number;
  dweb: boolean;
  cache: boolean;
  incognito: boolean;
}
