/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { NetworkControll } from 'app/lib/controller/network';
import { MobileStorage, buildObject } from 'app/lib';
import { STORAGE_FIELDS, APP_EXPLORER } from 'app/config';
import { DApp } from 'types';

export class AppsController {
  private _app = 'app_list';
  private _ad = 'ad_list';

  private _zilliqa: ZilliqaControl;
  private _storage: MobileStorage;
  private _netwrok: NetworkControll;

  constructor(storage: MobileStorage) {
    this._netwrok = new NetworkControll(storage);
    this._zilliqa = new ZilliqaControl(this._netwrok);
    this._storage = storage;
  }

  public async getAppsByCategory(category: number | string, force = false) {
    const field = this._field(category);
    const list = await this._storage.get(field);

    try {
      if (!list || typeof list !== 'string' || force) {
        throw new Error();
      }

      return JSON.parse(String(list));
    } catch {
      //
    }

    category = String(category);

    const result = await this._zilliqa.getSmartContractSubState(
      APP_EXPLORER,
      this._app,
      [category]
    );

    if (result && result[this._app] && result[this._app][category]) {
      const apps = Object.keys(result[this._app][category]).map((contract) => ({
        contract,
        title: result[this._app][category][contract].arguments[0],
        description: result[this._app][category][contract].arguments[1],
        url: result[this._app][category][contract].arguments[2],
        images: result[this._app][category][contract].arguments[3],
        icon: result[this._app][category][contract].arguments[4],
        category: result[this._app][category][contract].arguments[5]
      }));

      await this._cahce(apps, field);

      return apps;
    }

    return [];
  }

  private _field(category: number | string) {
    return `${STORAGE_FIELDS.APPS}/${category}`;
  }

  private async _cahce(list: DApp[], field: string) {
    await this._storage.set(
      buildObject(field, list)
    );

    return list;
  }
}
