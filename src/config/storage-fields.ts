/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
const app = 'ZilPay';
const prefix = `@/${app}/`;

export const STORAGE_FIELDS = {
  VAULT: `${prefix}vault`,
  CONTACTS: `${prefix}contacts`,
  TOKENS: `${prefix}tokens`,
  THEME: `${prefix}theme`,
  SELECTED_COIN: `${prefix}selectedcoin`,
  SELECTED_NET: `${prefix}selectednet`,
  CONFIG: `${prefix}config`,
  ACCOUNTS: `${prefix}accounts`,
  TRANSACTIONS: `${prefix}transactions`,
  CURRENCY: `${prefix}currency`,
  CONNECTIONS: `${prefix}/connections`,
  GAS: `${prefix}gas_config`,
  APPS: `${prefix}apps_list`,
  POSTERS: `${prefix}poster_list`,
  BLOCK_NUMBER: `${prefix}blocknumber`,

  ACCESS_CONTROL: `${prefix}access_control`,
  SEARCH_ENGINE: `${prefix}search_engine`,
  SSN_LIST: `${prefix}ssn_list`,
  SETTINGS: `${prefix}settings`,
  NOTIFICATION: `${prefix}notification`,
};
