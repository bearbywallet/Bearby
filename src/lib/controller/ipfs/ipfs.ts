/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { ipfsStore, ipfsStoreReset, ipfsStoreUpdate, ipfsSelect } from './store';
import { MobileStorage, buildObject } from 'app/lib/storage';
import { STORAGE_FIELDS } from 'app/config';

export class IPFS {
  public readonly store = ipfsStore;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public get selected() {
    const state = this.store.get();
    return state.list[state.selected].url;
  }

  public async setSelected(index: number) {
    ipfsSelect(index);

    await this._storage.set(
      buildObject(STORAGE_FIELDS.IPFS, this.store.get())
    );
  }

  public async sync() {
    const data = await this._storage.get(STORAGE_FIELDS.IPFS);

    try {
      if (!data || typeof data !== 'string') {
        await this.reset();
      }

      const parsed = JSON.parse(data as string);

      if (parsed) {
        ipfsStoreUpdate(parsed);
      }
    } catch {
      await this.reset();
    }
  }

  public async reset() {
    ipfsStoreReset();

    const state = this.store.get();
    const list =  state.list.map(async(el) => {
      const t0 = performance.now();
      try {
        await fetch(el.url);

        el.value = String(performance.now() - t0);
      } catch {
        el.value = String(performance.now() - t0);
      }

      return el;
    });
    const newList = await Promise.all(list);

    state.list = newList
      .sort((a, b) => Number(a.value) - Number(b.value))
      .map((el) => ({
        ...el,
        value: `${Number(el.value).toFixed()}ms`
      }));

    ipfsStoreUpdate(state);

    await this._storage.set(
      buildObject(STORAGE_FIELDS.IPFS, state)
    );
  }
}
