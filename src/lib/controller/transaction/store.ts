/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';
import { Transaction } from 'types';

const initalState: Transaction[] = [];
export const transactionStore = newRidgeState<Transaction[]>(initalState);

export function transactionStoreUpdate(txns: Transaction[]) {
  transactionStore.set(() => txns);
}
export function transactionStoreReset() {
  transactionStore.reset();
}
