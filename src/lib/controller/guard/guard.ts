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
import Keychain from 'react-native-keychain';
import { STORAGE_FIELDS } from 'app/config';

// this property is responsible for control session.
let _isEnable = false;
// this property is responsible for control wallet.
let _isReady = false;

export class GuardControler {
  private _storage: MobileStorage;
  private _auth: KeychainControler;

  constructor(storage: MobileStorage) {
    this._storage = storage;
    this._auth = new KeychainControler(storage);
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

  public async setupWallet(
    password: string,
    mnemonic: string,
    biometric?: Keychain.ACCESS_CONTROL
  ) {
    const encrypted = await this._auth.encryptVault(mnemonic, password);
    await this._storage.set(
      buildObject(STORAGE_FIELDS.VAULT, encrypted)
    );

    if (biometric) {
      this._auth.initKeychain(password, biometric);
    }

    _isEnable = true;
    _isReady = true;
  }

  public async unlock(password: string) {
    const encrypted = await this._storage.get<string>(STORAGE_FIELDS.VAULT);
    const cipher = JSON.parse(String(encrypted));

    await this._auth.decryptVault(cipher, password);
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

  public logout() {
    _isEnable = false;
  }

  public async sync() {
    this._auth.sync();

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
