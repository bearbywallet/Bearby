/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { adStore, adStoreReset, adStoreUpdate } from './store';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { NetworkControll } from 'app/lib/controller/network';
import { MobileStorage, buildObject } from 'app/lib';
import {
  STORAGE_FIELDS,
  APP_EXPLORER,
  MIN_POSTERS_CAHCE
} from 'app/config';
import { DApp, Poster } from 'types';
import { shuffle } from 'app/utils';

export class AppsController {
  public store = adStore;

  private _app = 'app_list';
  private _ad = 'ad_list';

  private _zilliqa: ZilliqaControl;
  private _storage: MobileStorage;
  private _netwrok: NetworkControll;

  constructor(storage: MobileStorage) {
    this._netwrok = new NetworkControll(storage, true);
    this._zilliqa = new ZilliqaControl(this._netwrok);
    this._storage = storage;
  }

  public async getBanners(blockNumber: number, force = false) {
    const list = await this._storage.get(STORAGE_FIELDS.POSTERS);

    try {
      if (!list || typeof list !== 'string' || force) {
        throw new Error();
      }

      const parsed = JSON.parse(String(list)).filter(
        (p: Poster) => Number(p.block) >= blockNumber
      );

      await this._cahce(parsed, STORAGE_FIELDS.POSTERS);

      if (parsed.length <= MIN_POSTERS_CAHCE) {
        throw new Error();
      }

      const [random] = shuffle<Poster>(parsed);

      if (random) {
        adStoreUpdate(random);
      }

      return parsed;
    } catch {
      adStoreReset();
    }

    const result = await this._zilliqa.getSmartContractSubState(
      APP_EXPLORER,
      this._ad
    );

    if (result && result[this._ad]) {
      const key = 'arguments';
      const posters = Object.values<object>(result[this._ad]).map((p) => ({
        block: p[key][0],
        url: p[key][1],
        banner: p[key][2]
      })).filter((p: Poster) => Number(p.block) >= blockNumber);
      const [random] = shuffle<Poster>(posters);

      adStoreUpdate(random);

      await this._cahce(posters, STORAGE_FIELDS.POSTERS);

      return posters;
    }

    return [];
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

  private async _cahce(list: DApp[] | Poster[], field: string) {
    await this._storage.set(
      buildObject(field, list)
    );

    return list;
  }
}
