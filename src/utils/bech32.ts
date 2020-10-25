/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { isAddress , tohexString, toChecksumAddress } from './address';

const CHARSET = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
const HRP = 'zil';
const GENERATOR = [
  0x3b6a57b2,
  0x26508e6d,
  0x1ea119fa,
  0x3d4233dd,
  0x2a1462b3
];

const polymod = (values: Buffer): number => {
  let chk = 1;
  // tslint:disable-next-line
  for (let p = 0; p < values.length; ++p) {
    const top = chk >> 25;
    chk = ((chk & 0x1ffffff) << 5) ^ values[p];
    for (let i = 0; i < 5; ++i) {
      if ((top >> i) & 1) {
        chk ^= GENERATOR[i];
      }
    }
  }

  return chk;
};

const hrpExpand = (hrp: string): Buffer => {
  const ret = [];
  let p;
  for (p = 0; p < hrp.length; ++p) {
    ret.push(hrp.charCodeAt(p) >> 5);
  }
  ret.push(0);
  for (p = 0; p < hrp.length; ++p) {
    ret.push(hrp.charCodeAt(p) & 31);
  }
  return Buffer.from(ret);
};

/**
 * convertBits
 *
 * groups buffers of a certain width to buffers of the desired width.
 *
 * For example, converts byte buffers to buffers of maximum 5 bit numbers,
 * padding those numbers as necessary. Necessary for encoding Ethereum-style
 * addresses as bech32 ones.
 *
 * @param {Buffer} data
 * @param {number} fromWidth
 * @param {number} toWidth
 * @param {boolean} pad
 * @returns {Buffer|null}
 */
export function convertBits(data: Buffer, fromWidth: number, toWidth: number, pad: boolean = true): Buffer | null {
  let acc = 0;
  let bits = 0;
  const ret = [];
  const maxv = (1 << toWidth) - 1;
  // tslint:disable-next-line
  for (let p = 0; p < data.length; ++p) {
    const value = data[p];
    if (value < 0 || value >> fromWidth !== 0) {
      return null;
    }
    acc = (acc << fromWidth) | value;
    bits += fromWidth;
    while (bits >= toWidth) {
      bits -= toWidth;
      ret.push((acc >> bits) & maxv);
    }
  }

  if (pad) {
    if (bits > 0) {
      ret.push((acc << (toWidth - bits)) & maxv);
    }
  } else if (bits >= fromWidth || (acc << (toWidth - bits)) & maxv) {
    return null;
  }

  return Buffer.from(ret);
}

function verifyChecksum(hrp: string, data: Buffer) {
  return polymod(Buffer.concat([hrpExpand(hrp), data])) === 1;
}

function createChecksum(hrp: string, data: Buffer) {
  const values = Buffer.concat([
    Buffer.from(hrpExpand(hrp)),
    data,
    Buffer.from([0, 0, 0, 0, 0, 0]),
  ]);
  const mod = polymod(values) ^ 1;
  const ret = [];
  for (let p = 0; p < 6; ++p) {
    ret.push((mod >> (5 * (5 - p))) & 31);
  }
  return Buffer.from(ret);
}

export const encode = (hrp: string, data: Buffer) => {
  const combined = Buffer.concat([data, createChecksum(hrp, data)]);
  let ret = hrp + '1';
  // tslint:disable-next-line
  for (let p = 0; p < combined.length; ++p) {
    ret += CHARSET.charAt(combined[p]);
  }
  return ret;
};

export const decode = (bechString: string) => {
  let p;
  let hasLower = false;
  let hasUpper = false;
  for (p = 0; p < bechString.length; ++p) {
    if (bechString.charCodeAt(p) < 33 || bechString.charCodeAt(p) > 126) {
      return null;
    }
    if (bechString.charCodeAt(p) >= 97 && bechString.charCodeAt(p) <= 122) {
      hasLower = true;
    }
    if (bechString.charCodeAt(p) >= 65 && bechString.charCodeAt(p) <= 90) {
      hasUpper = true;
    }
  }
  if (hasLower && hasUpper) {
    return null;
  }
  bechString = bechString.toLowerCase();
  const pos = bechString.lastIndexOf('1');
  if (pos < 1 || pos + 7 > bechString.length || bechString.length > 90) {
    return null;
  }
  const hrp = bechString.substring(0, pos);
  const data = [];
  for (p = pos + 1; p < bechString.length; ++p) {
    const d = CHARSET.indexOf(bechString.charAt(p));
    if (d === -1) {
      return null;
    }
    data.push(d);
  }

  if (!verifyChecksum(hrp, Buffer.from(data))) {
    return null;
  }

  return { hrp, data: Buffer.from(data.slice(0, data.length - 6)) };
};

export const toBech32Address = (address: string): string => {
  isAddress(address);

  const normalizedAddress = tohexString(address);
  const addrBz = convertBits(
    Buffer.from(normalizedAddress, 'hex'),
    8,
    5,
  );

  if (addrBz === null) {
    throw new Error('Could not convert byte Buffer to 5-bit Buffer');
  }

  return encode(HRP, addrBz);
};

export const fromBech32Address = (address: string): string => {
  const res = decode(address);

  if (res === null) {
    throw new Error('Invalid bech32 address');
  }

  const { hrp, data } = res;

  const shouldBe = HRP;
  if (hrp !== shouldBe) {
    throw new Error(`Expected hrp to be ${shouldBe} but got ${hrp}`);
  }

  const buf = convertBits(data, 5, 8, false);

  if (buf === null) {
    throw new Error('Could not convert buffer to bytes');
  }

  return toChecksumAddress(buf.toString('hex'));
};
