/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { Transaction } from 'app/lib/controller';

export interface MessagePayload {
  origin?: string;
  title?: string;
  icon?: string;
  data?: object;
  uuid?: string;
}

export interface MessageType {
  type: string;
  payload: MessagePayload;
}

export interface TxParams {
  amount: string
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
}

export interface Signature {
  message: string;
  publicKey: string;
  signature: string;
}

export interface TxMessage {
  params: Transaction;
  origin: string;
  icon: string;
  uuid: string;
}
