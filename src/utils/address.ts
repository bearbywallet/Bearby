/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import BN from 'bn.js';
import hashjs from 'hash.js';

export function tohexString(hex: string) {
  return String(hex).toLowerCase().replace('0x', '');
}

export const isByteString = (str: string, len: number) => {
  return !!tohexString(str).match(`^[0-9a-fA-F]{${len}}$`);
};

export const isAddress = (address: string) => {
  if (!isByteString(address, 40)) {
    throw new Error(`${address} is not a valid base 16 address`);
  }
};

export const toChecksumAddress = (address: string): string => {
  isAddress(address);

  address = tohexString(address);
  const hash = hashjs
    .sha256()
    .update(address, 'hex')
    .digest('hex');
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

export const getAddressFromPublicKey = (publicKey: string) => {
  const pub = tohexString(publicKey);
  const hash = hashjs
    .sha256()
    .update(pub, 'hex')
    .digest('hex')
    .slice(24);

  return toChecksumAddress(hash);
};
