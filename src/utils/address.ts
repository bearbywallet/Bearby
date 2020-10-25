/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import BN from 'bn.js';
import { sha256 } from '../lib/crypto';

export function tohexString(hex: string) {
  return String(hex).toLowerCase().replace('0x', '');
}

export const isByteString = (str: string, len: number) => {
  return !!tohexString(str).match(`^[0-9a-fA-F]{${len}}$`);
};

export const isAddress = (address: string) => {
  return isByteString(address, 40);
};

export const toChecksumAddress = async (address: string): Promise<string> => {
  if (!isAddress(address)) {
    throw new Error(`${address} is not a valid base 16 address`);
  }

  address = tohexString(address);
  const hash = await sha256(address);
  const v = new BN(hash, 'hex', 'be');
  let ret = '0x';

  for (let i = 0; i < address.length; i++) {
    if ('0123456789'.indexOf(address[i]) !== -1) {
      ret += address[i];
    } else {
      ret += v.and(new BN(2).pow(new BN(255 - 6 * i))).gte(new BN(1))
        ? address[i].toUpperCase()
        : address[i].toLowerCase();
    }
  }

  return ret;
};

export const getAddressFromPublicKey = async (publicKey: string) => {
  const normalized = tohexString(publicKey);
  const hash = await sha256(normalized);

  return toChecksumAddress(hash.slice(24));
};
