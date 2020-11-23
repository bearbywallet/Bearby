/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from 'app/lib/storage';
import { KeychainControler } from 'app/lib/controller/auth';
import { STORAGE_FIELDS } from 'app/config';

// this property is responsible for control session.
let _isEnable = false;
// this property is responsible for control wallet.
let _isReady = false;

export class GuardControler {
  public auth: KeychainControler;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
    this.auth = new KeychainControler(storage);
  }

  public get self() {
    return {
      isEnable: _isEnable,
      isReady: _isReady
    };
  }

  public get isEnable() {
    return _isEnable;
  }

  public get isReady() {
    return _isReady;
  }

  public async setupWallet(password: string, mnemonic: string) {
    const encrypted = await this.auth.encryptVault(mnemonic, password);
    await this._storage.set(
      buildObject(STORAGE_FIELDS.VAULT, encrypted)
    );

    _isEnable = true;
    _isReady = true;
  }

  public async unlock(password?: string) {
    const encrypted = await this._storage.get<string>(STORAGE_FIELDS.VAULT);
    const cipher = JSON.parse(String(encrypted));

    await this.auth.decryptVault(cipher, password);

    _isEnable = true;
  }

  public async getMnemonic(password?: string) {
    const encrypted = await this._storage.get<string>(STORAGE_FIELDS.VAULT);
    const cipher = JSON.parse(String(encrypted));

    return this.auth.decryptVault(cipher, password);
  }

  public async getPassword() {
    return this.auth.secureKeychain.getGenericPassword();
  }

  public logout() {
    _isEnable = false;
  }

  public async sync() {
    this.auth.sync();

    const vault = await this._storage.get<string>(
      STORAGE_FIELDS.VAULT
    );

    if (vault) {
      _isEnable = false;
      _isReady = true;
    } else {
      _isEnable = false;
      _isReady = false;
    }
  }
}
