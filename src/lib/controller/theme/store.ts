/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { DEFAULT_THEMES } from 'app/config';
import { newRidgeState } from 'react-ridge-state';

const [initalState] = DEFAULT_THEMES;
export const themesStore = newRidgeState<string>(initalState);

export function themesStoreUpdate(selected: string) {
  themesStore.set(() => selected);
}
export function themesStoreReset() {
  themesStore.reset();
}
