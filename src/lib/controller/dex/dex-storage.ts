/*
 * Project: ZilPay-wallet
 * Author: Rinat(hiccaru)
 * -----
 * Modified By: the developer formerly known as Rinat(hiccaru) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2022 ZilPay
 */
import {
  STORAGE_FIELDS
} from 'app/config';
import { buildObject, MobileStorage } from 'app/lib/storage';
import {
  dexStore,
  dexStoreReset,
  dexStoreSetFee,
  dexStoreSetSettings,
  dexStoreUpdate
} from './state';


export class DexStorage {
  public readonly store = dexStore;

  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public async updateSlippage(slippage: number) {
    const { blocks } = this.store.get();

    dexStoreSetSettings(slippage, blocks);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.DEX_SETTINGS, this.store.get())
    );
  }

  public async updateBlocks(blocks: number) {
    const { slippage } = this.store.get();

    dexStoreSetSettings(slippage, blocks);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.DEX_SETTINGS, this.store.get())
    );
  }

  public async updateliquidityFee(liquidityFee: number) {
    const { protocolFee } = this.store.get();

    dexStoreSetFee(liquidityFee, protocolFee);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.DEX_SETTINGS, this.store.get())
    );
  }

  public async updateCashback(protocolFee: number) {
    const { liquidityFee } = this.store.get();

    dexStoreSetFee(liquidityFee, protocolFee);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.DEX_SETTINGS, this.store.get())
    );
  }

  public async sync() {
    const settings = await this._storage.get(
      STORAGE_FIELDS.DEX_SETTINGS
    );

    if (settings && typeof settings === 'string') {
      try {
        const cahce = JSON.parse(settings);

        dexStoreUpdate(cahce);
      } catch {
        await this.reset();
      }
    } else {
      await this.reset();
    }
  }

  public async reset() {
    dexStoreReset();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.DEX_SETTINGS, this.store.get())
    );
  }
}