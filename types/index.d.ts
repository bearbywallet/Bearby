/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
export * from './store';
export * from './inpage';
export * from './ssn';

export interface ZilliqaNetwork {
  [key: string]: {
    PROVIDER: string;
    WS: string;
    MSG_VERSION: number
  }
}

type getBase64 = (event: string) => void;

export interface QrcodeType {
  toDataURL: (cb: getBase64) => void;
}
