/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { NativeModules } from 'react-native';
import { base64ToByteArray } from './base64';

const { Crypto, CryptoModule } = NativeModules;

export async function getRandomBytes(length: number) {
  if (Crypto) {
    return Crypto.randomBytes(length);
  }

  if (CryptoModule) {
    return CryptoModule.randomBytes(length);
  }

  return Array
    .from({ length }, () => Math.floor(Math.random() * 10));
}

/**
 * randomBytes
 *
 * Uses JS-native CSPRNG to generate a specified number of bytes.
 * NOTE: this method throws if no PRNG is available.
 *
 * @param {number} bytes
 * @returns {string}
 */
export const randomBytes = async (bytes: number) => {
  const base64Random = await getRandomBytes(bytes);
  const nativeBytes = new Uint8Array(base64ToByteArray(base64Random));
  let randBz: number[] | Uint8Array;

  const b = Buffer
    .allocUnsafe(bytes)
    .map((_, index) => nativeBytes[index]);
  randBz = new Uint8Array(
    b.buffer,
    b.byteOffset,
    b.byteLength / Uint8Array.BYTES_PER_ELEMENT,
  );

  let randStr = '';
  for (let i = 0; i < bytes; i++) {
    randStr += ('00' + randBz[i].toString(16)).slice(-2);
  }

  return randStr;
};
