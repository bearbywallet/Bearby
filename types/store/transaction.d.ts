/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { StatusCodes } from 'app/lib/controller/transaction';

export interface TxParams {
  amount: string;
  code: string;
  data: string;
  gasLimit: string;
  gasPrice: string;
  nonce: number;
  priority: boolean;
  pubKey: string;
  signature?: string;
  toAddr: string;
  version?: number;
  hash?: string;
}
export interface StoredTx {
  status: StatusCodes;
  confirmed?: boolean;
  token: {
    decimals: number;
    symbol: string;
  },
  info?: string;
  teg: string;
  amount: string;
  type: number;
  fee: string;
  nonce: number;
  toAddr: string;
  from: string;
  hash: string;
  timestamp: number;
}
