/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import {
  contactsStore,
  contactsStoreReset,
  contactsStoreUpdate
} from './store';
import { MobileStorage, buildObject } from 'app/lib/storage';
import {
  STORAGE_FIELDS
} from 'app/config';
import { Contact } from 'types';

export class ContactsControler {
  public readonly store = contactsStore;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public add(contact: Contact) {
    const contacts = this.store.get();

    contacts.push(contact);

    contactsStoreUpdate(contacts);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.CONTACTS, contacts)
    );
  }

  public rm(contact: Contact) {
    const contacts = this
      .store
      .get()
      .filter((acc) => acc.address !== contact.address);

    contactsStoreUpdate(contacts);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.CONTACTS, contacts)
    );
  }

  public reset() {
    contactsStoreReset();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.CONTACTS, this.store.get())
    );
  }

  public async sync() {
    const contacts = await this._storage.get(
      STORAGE_FIELDS.CONTACTS
    );

    if (contacts && typeof contacts === 'string') {
      try {
        const list = JSON.parse(contacts);

        if (Array.isArray(list)) {
          contactsStoreUpdate(list);
        }
      } catch {
        await this.reset();
      }
    } else {
      await this.reset();
    }
  }
}
