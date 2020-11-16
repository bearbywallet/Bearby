/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain, createEvent } from 'effector';
import { AccountState } from 'types';

export const accountStoreUpdate = createEvent<AccountState>();
export const accountStoreReset = createEvent();

const AccountDomain = createDomain();
const initalState: AccountState = {
  identities: [],
  selectedAddress: 0
};
export const accountStore = AccountDomain
  .store<AccountState>(initalState)
  .on(accountStoreUpdate, (_, payload) => payload)
  .reset(accountStoreReset);
