/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
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

export interface Signature {
  message: string;
  publicKey: string;
  signature: string;
}
