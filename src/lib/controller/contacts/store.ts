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
const initalState: Contact[] = [];
export const contactsStore = ContactsDomain
  .store<Contact[]>(initalState)
  .on(contactsStoreUpdate, (_, payload) => payload)
  .reset(contactsStoreReset);
