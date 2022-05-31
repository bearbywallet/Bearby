/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2022 ZilPay
 */
import Big from 'big.js';
import { Token } from './token';


export interface DexState {
  liquidityFee: number;
  protocolFee: number;
  slippage: number;
  blocks: number;
  rewarded: string;
  contract: {
    [net: string]: string;
  }
}


export interface TokenValue {
  value: string;
  meta: Token;
  converted?: number;
  approved: string;
}
