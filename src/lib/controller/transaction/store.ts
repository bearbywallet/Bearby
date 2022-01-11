/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';
import { StoredTx } from 'types';
import { MAX_TX_QUEUE } from 'app/config';
import { deppUnlink } from 'app/utils/deep-unlink';

const initalState: StoredTx[] = [];
export const transactionStore = newRidgeState<StoredTx[]>(initalState);

export function transactionStoreUpdate(txns: StoredTx[]) {
  transactionStore.set(() => deppUnlink(txns.filter(Boolean)));
}
export function transactionStoreAdd(txn: StoredTx) {

  if (!txn) {
    throw new Error('Tx cannobe null');
  }

  transactionStore.set((state) => {
    const newList = [txn, ...state];

    // Circumcision Array.
    newList.length = MAX_TX_QUEUE;

    return deppUnlink(newList.filter(Boolean));
  });
}
export function transactionStoreReset() {
  transactionStore.reset();
}
