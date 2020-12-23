/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';
import { TransactionType } from 'types';

const initalState: TransactionType[] = [];
export const transactionStore = newRidgeState<TransactionType[]>(initalState);

export function transactionStoreUpdate(txns: TransactionType[]) {
  transactionStore.set(() => txns);
}
export function transactionStoreAdd(txn: TransactionType) {
  transactionStore.set((state) => [txn, ...state]);
}
export function transactionStoreReset() {
  transactionStore.reset();
}
