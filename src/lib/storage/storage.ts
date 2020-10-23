/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import AsyncStorage from '@react-native-community/async-storage';
import { buildObject, buildObjectType } from './value-builder';

/**
 * Default class for working with browser Storage.
 * @example
 * import { MobileStorage } from 'lib/storage'
 * new MobileStorage().get('KEY')
 */
export class MobileStorage {

  /**
   * Set value by someting key.
   * @param {Object, String, Number, Array} value - Any value for set storage.
   * @returns {Promise<null | undefined>}
   * @example
   * import { MobileStorage, buildObject } from 'lib/storage'
   * const storage = new MobileStorage()
   * storage.set(
   *   buildObject('example-key', { example: 'set method'})
   * ).then(/ Do something... /)
   * // OR
   * storage.set([
   *   buildObject('key-1', new Object()),
   *   buildObject('key-2', new Object())
   *   //...
   * ]).then(/ Do something... /)
   */
  public set(...value: buildObjectType[]): Promise<void> {
    const values = value.map((object) => [object.key, object.value]);

    return AsyncStorage.multiSet(values);
  }

  /**
   * Get value from storage by keys.
   * @param {String, Number} keys - key or keys.
   * @example
   * import { MobileStorage } from 'lib/storage'
   * const storage = new MobileStorage()
   * storage.get(key).then(recievePaylod => / Do something... /)
   */
  public get(..._keys: string[]): Promise<any> {
    if (_keys.length === 1) {
      return new Promise((resolve, reject) => {
        AsyncStorage.getItem(_keys[0], (err, result) => {
          if (err) {
            return reject(err);
          }

          return resolve(result);
        });
      });
    }

    return new Promise((resolve, reject) => {
      AsyncStorage.multiGet(_keys, (err, result) => {
        if (err || !result) {
          return reject(err || result);
        }

        const values: { [key: string]: string | object | number | null } = {};

        for (const [key, value] of result) {
          values[key] = value;
        }

        return resolve(values);
      });
    });
  }

  public async getAll() {
    const keys = await this.getAllKeys();

    if (!keys || keys.length === 0) {
      return null;
    }

    return this.get(...keys);
  }

  /**
   * @returns {Object} - return all storage keys.
   * @example
   * import { MobileStorage } from 'lib/storage'
   * const storage = new MobileStorage()
   * storage.getAll(key).then(fullStorageObject => / Do something... /)
   */
  public getAllKeys(): Promise<string[]> {
    return new Promise((resolve, reject) => {
      AsyncStorage.getAllKeys(async (err, result) => {
        if (err) {
          return reject(err);
        }

        return resolve(result);
      });
    });
  }

  /**
   * Remove one item from storage.
   * @param {String, Number} keys - key or keys.
   * @returns {Promise<null | undefined>}
   * @example
   * import { MobileStorage } from 'lib/storage'
   * const storage = new MobileStorage()
   * storage.rm('any-key-item').then(() => / Do something... /)
   */
  public rm(...keys: string[]) {
    AsyncStorage.multiRemove(keys);
  }

  /**
   * Clear all storage data.
   * @returns {Promise<null | undefined>}
   * @example
   * import { MobileStorage } from 'lib/storage'
   * const storage = new MobileStorage()
   * storage.clear().then(() => / Do something... /)
   */
  public clear() {
    return AsyncStorage.clear();
  }

}