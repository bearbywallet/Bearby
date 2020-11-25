/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain, createEvent } from 'effector';
import { Contact } from 'types';

export const contactsStoreUpdate = createEvent<Contact[]>();
export const contactsStoreReset = createEvent();

const ContactsDomain = createDomain();
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
export const contactsStore = ContactsDomain
  .store<Contact[]>(initalState)
  .on(contactsStoreUpdate, (_, payload) => payload)
  .reset(contactsStoreReset);
