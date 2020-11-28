/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain, createEvent } from 'effector';
import { Transaction } from 'types';

export const transactionStoreUpdate = createEvent<Transaction[]>();
export const transactionStoreReset = createEvent();

const transactionDomain = createDomain();
const initalState: Transaction[] = [];
export const transactionStore = transactionDomain
  .store<Transaction[]>(initalState)
  .on(transactionStoreUpdate, (_, payload) => payload)
  .reset(transactionStoreReset);
