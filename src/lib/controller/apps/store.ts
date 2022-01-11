/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';
import { Poster } from 'types';
import { deppUnlink } from 'app/utils/deep-unlink';

const initalState: Poster[] = [];
export const adStore = newRidgeState<Poster[]>(initalState);

export function adStoreUpdate(payload: Poster[]) {
  adStore.set(() => deppUnlink(payload));
}
export function adStoreReset() {
  adStore.reset();
}
