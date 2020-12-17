/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { Messages } from 'app/config/messages';
export interface MessagePayload {
  origin: string;
  icon?: string;
  data?: object;
}
export interface MessageType {
  type: Messages;
  payload: MessagePayload;
}
