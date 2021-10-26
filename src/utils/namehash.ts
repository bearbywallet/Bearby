/*
 * Project: ZilPay-wallet
 * Author: Rinat(hiccaru)
 * -----
 * Modified By: the developer formerly known as Rinat(hiccaru) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2021 ZilPay
 */
import hash from 'hash.js';

const sha256 = hash.sha256;
const ZERO_HASH = '0000000000000000000000000000000000000000000000000000000000000000';

export interface Parent {
  parent?: string;
  prefix?: boolean;
}

interface InputEnc {
  inputEnc?: string;
  outputEnc?: string;
  hexPrefix?: boolean;
}

function sha3(message: string, _a: InputEnc) {
  const _b = _a === void 0 ? {} : _a;
  const _d = _b.inputEnc;
  const inputEnc: "hex" | undefined = _d === void 0 ? undefined : 'hex';

  return sha256()
    .update(message, inputEnc)
    .digest('hex');
}

export function nameHash(name: string, p?: Parent) {
  if (name === void 0) {
    name = '';
  }

  const _b = p === void 0 ? {} : p;
  const _c = _b.parent;
  let parent = _c === void 0 ? null : _c;
  const _d = _b.prefix;
  const prefix = _d === void 0 ? true : _d;

  parent = parent || ZERO_HASH;

  if (parent.match(/^0x/)) {
    parent = parent.substring(2);
  }
  const address = [parent]
    .concat(name
    .split('.')
    .reverse()
    .filter((label) => label)
    .map((label) => sha3(label, { hexPrefix: false })))
    .reduce((a, labelHash) => {
      return sha3(a + labelHash, {
        hexPrefix: false,
        inputEnc: 'hex'
      });
    });
  return prefix ? '0x' + address : address;
}
