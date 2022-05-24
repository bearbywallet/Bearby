/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { TokenTypes } from 'app/config';

export interface Token {
  address: {
    [netwrok: string]: string;
  };
  decimals: number;
  default?: boolean;
  name: string;
  symbol: string;
  type: TokenTypes;
  totalSupply?: string;
  balance?: string;
  rate: number;
  pool: string[];
}

export interface ServerToken {
  id: number;
  bech32: string;
  base16: string;
  decimals: number;
  name: string;
  symbol: string;
  baseUri: string | null;
  scope: number;
  type: number;
}

export interface ServerResponse {
  list: ServerToken[];
  count: number;
}
