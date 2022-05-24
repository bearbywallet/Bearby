/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
type getBase64 = (event: string) => void;

export interface QrcodeType {
  toDataURL: (cb: getBase64) => void;
}

export interface BleState {
  available: boolean;
  type: string;
}

export interface ZilPayConnectContent {
  wallet: {
    selectedAddress: number;
    identities: {
      name: string;
      bech32: string;
      index: number;
      base16: string;
      type: number;
      pubKey: string;
      zrc2: {
        [key: string]: string;
      },
      nft: {}
    }[];
  }
  cipher: string;
  zrc2: {
    base16: string;
    bech32: string;
    decimals: number
    name: string;
    symbol: string;
    rate: number;
    pool: string[];
  }[];
  uuid: string;
  iv: string;
}

export interface EncryptedWallet {
  seed: string;
  keys: {
    privateKey: string;
    index: number;
  }[];
}
