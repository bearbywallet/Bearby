/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain } from 'effector';
import { Token } from '../../types';
import { ZILLIQA, NIL_ADDRESS } from '../config';

const [mainnet, testnet, privatenet] = Object.keys(ZILLIQA);
const TokenDomain = createDomain();


const identities: Token[] = [
  {
    address: {
      [mainnet]: NIL_ADDRESS,
      [testnet]: NIL_ADDRESS,
      [privatenet]: NIL_ADDRESS
    },
    balance: {
      [mainnet]: '0',
      [testnet]: '0',
      [privatenet]: '0'
    },
    decimals: 12,
    default: true,
    name: 'Zilliqa',
    symbol: 'ZIL'
  },
  {
    address: {
      [mainnet]: '0x173ca6770aa56eb00511dac8e6e13b3d7f16a5a5',
      [testnet]: '0x7f4a28aabde4cca04b5529eacb64b1449b317e7f'
    },
    balance: {
      [mainnet]: '0',
      [testnet]: '0'
    },
    decimals: 6,
    default: true,
    name: 'Singapore dollar',
    symbol: 'XSGD'
  },
  {
    address: {
      [mainnet]: '0xfbd07e692543d3064b9cf570b27faabfd7948da4',
      [testnet]: '0x6f0b1fbda199dc4abfda28fa2eaa299599b3e8f2'
    },
    balance: {
      [mainnet]: '0',
      [testnet]: '0'
    },
    decimals: 18,
    default: true,
    name: 'ZilPay wallet',
    symbol: 'ZLP'
  },
  {
    address: {
      [mainnet]: '0xa845c1034cd077bd8d32be0447239c7e4be6cb21',
      [testnet]: '0x7b949726966b80c93542233531f9bd53542d4514'
    },
    balance: {
      [mainnet]: '0',
      [testnet]: '0'
    },
    decimals: 15,
    default: true,
    name: 'Governance ZIL',
    symbol: 'gZIL'
  }
];
const initalState = {
  identities
};
const store = TokenDomain
  .store(initalState);

export default {
  store
};
