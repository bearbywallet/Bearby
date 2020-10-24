/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { ZilliqaNetwork } from 'types';

export const FIAT_ORDERS = {
  TRANSAK_URL: 'https://global.transak.com/',
  TRANSAK_URL_STAGING: 'https://staging-global.transak.com/',
  TRANSAK_API_URL_PRODUCTION: 'https://api.transak.com/',
  TRANSAK_API_URL_STAGING: 'https://staging-api.transak.com/',
  WYRE_API_ENDPOINT: 'https://api.sendwyre.com/',
  WYRE_API_ENDPOINT_TEST: 'https://api.testwyre.com/'
};

export const ZILLIQA: ZilliqaNetwork = {
  mainnet: {
    PROVIDER: 'https://api.zilliqa.com',
    WS: 'wss://api-ws.zilliqa.com',
    MSG_VERSION: 1
  },
  testnet: {
    PROVIDER: 'https://dev-api.zilliqa.com',
    WS: 'wss://dev-ws.zilliqa.com',
    MSG_VERSION: 1
  },
  private: {
    PROVIDER: 'http://127.0.0.1:4200',
    WS: 'ws://127.0.0.1:4200',
    MSG_VERSION: 1
  }
};

export const ZIL_SWAP_CONTRACTS = {
  [Object.keys(ZILLIQA)[0]]: '0xBa11eB7bCc0a02e947ACF03Cc651Bfaf19C9EC00',
  [Object.keys(ZILLIQA)[1]]: '0x1a62Dd9C84b0C8948cb51FC664ba143e7A34985c'
};

/**
 * Default tokens will add to tokens list, this token cannot remove.
 */
export const DEFAULT_TOKENS_LIST = {
  [Object.keys(ZILLIQA)[0]]: [
    '0x173Ca6770Aa56EB00511Dac8e6E13B3D7f16a5a5',
    '0xfbd07e692543d3064B9CF570b27faaBfd7948DA4',
    '0xa845C1034CD077bD8D32be0447239c7E4be6cb21'
  ],
  [Object.keys(ZILLIQA)[1]]: [
    '0x7b949726966b80c93542233531f9bd53542d4514',
    '0x7f4a28aabde4cca04b5529eacb64b1449b317e7f',
    '0x6f0B1fbDA199dc4AbFda28fa2eaa299599b3e8F2'
  ]
};

export const MNEMONIC_PACH = "m/44'/313'/0'/0/index";
