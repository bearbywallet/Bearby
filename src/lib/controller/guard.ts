/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from '../storage';
import { AuthControler, Auth } from './auth';
import { STORAGE_FIELDS } from '../../config';

// this property is responsible for control session.
let _isEnable = false;
// this property is responsible for control wallet.
let _isReady = false;

export class GuardControler {
  private _storage: MobileStorage;
  private _auth?: Auth;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public get isEnable() {
    return _isEnable;
  }

  public get isReady() {
    return _isReady;
  }

  public async setupWallet(password: string, mnemonic: string) {
    this._auth = await AuthControler(password);
    await this._auth.encryptVault(mnemonic);
    await this._storage.set(
      buildObject(STORAGE_FIELDS.VAULT, this._auth.getEncrypted())
    );

    _isEnable = true;
    _isReady = true;
  }

  public async unlock(password: string) {
    const encrypted = await this._storage.get(STORAGE_FIELDS.VAULT);
    const cipher = JSON.parse(encrypted as string);

    this._auth = await AuthControler(password, cipher);

    await this._auth.decryptVault();
  }

  public getMnemonic() {
    if (!this.isEnable) {
      throw new Error('wallet is disabled');
    } else if (!this.isReady) {
      throw new Error('wallet is not ready');
    } else if (!this._auth) {
      throw new Error('guard is not initialized');
    }

    return this._auth.decryptVault();
  }
}
