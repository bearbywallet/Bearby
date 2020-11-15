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

export const NIL_ADDRESS = '0x0000000000000000000000000000000000000000';
export const TOKEN_ICONS = 'https://raw.githubusercontent.com/Switcheo/zilswap-token-list/master/logos';
export const PASSWORD_DIFFICULTY = 6;
export const MAX_NAME_DIFFICULTY = 10;

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
const [mainnet, testnet] = Object.keys(ZILLIQA);

export const ZIL_SWAP_CONTRACTS = {
  [mainnet]: '0xBa11eB7bCc0a02e947ACF03Cc651Bfaf19C9EC00',
  [testnet]: '0x1a62Dd9C84b0C8948cb51FC664ba143e7A34985c'
};

export const MNEMONIC_PACH = "m/44'/313'/0'/0/index";
