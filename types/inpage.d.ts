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
  domain?: string;
  title?: string;
  icon?: string;
  data?: object;
  content?: string;
  uuid?: string;
}

export interface MessageType {
  type: string;
  payload: {
    resolve?: object;
    reject?: string;
  };
}

export interface Signature {
  message: string;
  publicKey: string;
  signature: string;
}

export interface TxMessage {
  params: Transaction;
  domain: string;
  icon: string;
  uuid: string;
}
