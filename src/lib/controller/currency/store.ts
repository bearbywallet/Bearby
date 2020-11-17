/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain, createEvent } from 'effector';
import { DEFAULT_CURRENCIES } from 'app/config';

export const currenciesStoreUpdate = createEvent<string>();
export const CurrenciesStoreReset = createEvent();

const CurrenciesDomain = createDomain();
const [initalState] = DEFAULT_CURRENCIES;
export const currenciesStore = CurrenciesDomain
  .store<string>(initalState)
  .reset(CurrenciesStoreReset)
  .on(currenciesStoreUpdate, (_, value) => value);
