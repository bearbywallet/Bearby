/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
export interface Transaction {
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
  events: object[];
}
