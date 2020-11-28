/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { DEFAULT_CURRENCIES } from 'app/config';
import { newRidgeState } from 'react-ridge-state';

const [initalState] = DEFAULT_CURRENCIES;
export const currenciesStore = newRidgeState<string>(initalState);

export function currenciesStoreUpdate(payload: string) {
  currenciesStore.set(() => payload);
}
export function currenciesStoreReset() {
  currenciesStore.reset();
}
