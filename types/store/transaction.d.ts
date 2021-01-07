/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
export interface TransactionType {
  hash: string;
  blockHeight: number;
  from: string;
  to: string;
  value: string;
  fee: string;
  timestamp: number;
  direction: string;
  nonce: number;
  receiptSuccess?: boolean;
  data: string | null;
  code: string | null;
  events?: object[];
}

export interface ZilliqaArgType {
  type: string;
  value: string;
  vname: string;
}

export interface ZilliqaEventType {
  _eventname: string;
  address: string;
  params: ZilliqaArgType[];
}

export interface ZIlliqaMSGType {
  _amount: string;
  _recipient: string;
  _tag: string;
  params: ZilliqaArgType[];
}

export interface ZIlliqaTransitionType {
  accepted: boolean;
  addr: string;
  depth: number;
  msg: ZIlliqaMSGType;
}

export interface ZilliqaException {
  line: number;
  message: string;
}

export interface ZilliqaTransactionType {
  ID: string;
  amount: string;
  gasLimit: string;
  gasPrice: string;
  nonce: string;
  receipt: {
    cumulative_gas: string;
    epoch_num: string;
    success: boolean;
    errors?: number[];
    event_logs?: ZilliqaEventType[];
    transitions?: ZIlliqaTransitionType[];
    exceptions?: ZilliqaException[];
  };
  senderPubKey: string;
  signature: string;
  toAddr: string;
  version: string;
}
