/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from 'app/lib/storage';
import { ZilliqaControl, NetworkControll } from 'app/lib/controller';
import { STORAGE_FIELDS, DEFAULT_SSN, ZILLIQA_KEYS } from 'app/config';
import {
  ssnStore,
  StoreUpdate,
  selectSsnStoreUpdate,
  ssnStoreUpdate
} from './store';

export class SSnController {
  public store = ssnStore;

  private _storage: MobileStorage;
  private _zilliqa: ZilliqaControl;
  private _network: NetworkControll;

  constructor(
    storage: MobileStorage,
    zilliqa: ZilliqaControl,
    network: NetworkControll
  ) {
    this._zilliqa = zilliqa;
    this._storage = storage;
    this._network = network;
  }

  public get field() {
    return `${STORAGE_FIELDS.SSN_LIST}/${this._network.selected}`;
  }

  public async sync() {
    const ssnList = await this._storage.get(this.field);

    try {
      if (!ssnList || typeof ssnList !== 'string') {
        return;
      }

      const parsed = JSON.parse(ssnList as string);

      if (parsed) {
        StoreUpdate(parsed);
      }
    } catch {
      ////
    }
  }

  public async changeSSn(selected: string) {
    const found = this.store.get().list.find((ssn) => ssn.name === selected);

    if (!found) {
      throw new Error('Not found');
    }

    const { config } = this._network;

    config[this._network.selected].PROVIDER = found.api;

    selectSsnStoreUpdate(selected);

    await this._storage.set(
      buildObject(this.field, this.store.get())
    );
    await this._network.changeConfig(config);
  }

  public async updateList() {
    const [mainnet] = ZILLIQA_KEYS;
    if (this._network.selected === mainnet) {
      const list = await this._zilliqa.getSSnList();

      ssnStoreUpdate(list);

      await this._storage.set(
        buildObject(this.field, this.store.get())
      );
    }
  }

  public async reset() {
    let { list } = this.store.get();

    if ((!list || list.length === 0) && this._network.selected === ZILLIQA_KEYS[0]) {
      list = await this._zilliqa.getSSnList();
    }

    StoreUpdate({
      selected: DEFAULT_SSN,
      list
    });
    await this._storage.set(
      buildObject(this.field, this.store.get())
    );
  }
}
