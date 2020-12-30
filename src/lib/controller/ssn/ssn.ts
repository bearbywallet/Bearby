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
import { STORAGE_FIELDS, DEFAULT_SSN } from 'app/config';
import { SSN, SSNState } from 'types';
import { ssnStore, StoreUpdate, selectSsnStoreUpdate } from './store';

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
        throw new Error('incorect data');
      }

      const parsed = JSON.parse(ssnList as string);

      StoreUpdate(parsed);
    } catch {
      await this.reset();
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

    await this._update(this.store.get());
    await this._network.changeConfig(config);
  }

  public async reset() {
    const list = await this._zilliqa.getSSnList();

    await this._update({
      selected: DEFAULT_SSN,
      list
    });
  }

  private async _update(state: SSNState) {
    StoreUpdate(state);

    await this._storage.set(
      buildObject(this.field, state)
    );
  }
}
