/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { Contact } from 'types';

import { newRidgeState } from 'react-ridge-state';

const initalState: Contact[] = [
  {
    address: 'zil1wl38cwww2u3g8wzgutxlxtxwwc0rf7jf27zace',
    name: 'zilpay'
  },
  {
    address: 'zil1gmk7xpsyxthczk202a0yavhxk56mqch0ghl02f',
    name: 'DragonZIL'
  },
  {
    address: 'zil1dnztgf0upz2tf6tkrsdx4jnf5wax7w9rdqwr0f',
    name: 'ledger'
  },
];
export const contactsStore = newRidgeState<Contact[]>(initalState);

export function contactsStoreUpdate(payload: Contact[]) {
  contactsStore.set(() => payload);
}
export function accountStoreSelect(selectedAddress: number) {
  contactsStore.set((prevState) => ({
    ...prevState,
    selectedAddress
  }));
}
export function contactsStoreReset() {
  contactsStore.reset();
}
