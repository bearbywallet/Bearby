/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { ZilliqaNetwork } from 'types';

export const ORDERS = {
  TRANSAK_URL: 'https://global.transak.com/',
  FAUCET: 'https://dev-wallet.zilliqa.com/faucet'
};

export const API_COINGECKO = 'https://api.coingecko.com/api/v3/simple/price';
export const PINTA = 'https://gateway.pinata.cloud/ipfs';
export const NIL_ADDRESS = '0x0000000000000000000000000000000000000000';
export const UD_CONTRACT_ADDRESS = '0x9611c53be6d1b32058b2747bdececed7e1216793';
export const SCAM_TOKEN = '0xe66593414Ba537e965b5e0eB723a58b4d1fACc89';
export const TOKEN_ICONS = 'https://raw.githubusercontent.com/Switcheo/zilswap-token-list/master/logos';
export const PASSWORD_DIFFICULTY = 6;
export const MAX_NAME_DIFFICULTY = 10;
export const NONCE_DIFFICULTY = 10;
export const BLOCK_INTERVAL = 15000;
export const MAX_TX_QUEUE = 20;

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
export const ZILLIQA_KEYS = Object.keys(ZILLIQA);
const [mainnet, testnet] = ZILLIQA_KEYS;
export const DEFAULT_SSN = 'Main';
export const SSN_ADDRESS = {
  [mainnet]: '0xB780e8095b8BA85A7145965ed632b3B774ac51cE',
  [testnet]: '0x05c2ddec2e4449160436130cb4f9b84de9f7ee5b'
};
export const ZIL_SWAP_CONTRACTS = {
  [mainnet]: '0xBa11eB7bCc0a02e947ACF03Cc651Bfaf19C9EC00',
  [testnet]: '0x1a62Dd9C84b0C8948cb51FC664ba143e7A34985c'
};

export const MNEMONIC_PACH = "m/44'/313'/0'/0/index";
