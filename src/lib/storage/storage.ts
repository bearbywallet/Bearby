/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import AsyncStorage from '@react-native-community/async-storage';
import { buildObjectType } from './value-builder';

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
   * Cat return storage content by a lot of keys
   * @param _keys - an Array of args.
   * @extends
   * import { MobileStorage } from 'lib/storage';
   * const storage = new MobileStorage();
   * storage
   *   .get('key0', 'key1', 'key2')
   *   .then(recievePaylod => / Do something... /)
   */
  public multiGet<T>(..._keys: string[]): Promise<{ [key: string]: T }> {
    return new Promise((resolve, reject) => {
      AsyncStorage.multiGet(_keys, (err, result) => {
        if (err || !result) {
          return reject(err || result);
        }

        const values: { [key: string]: T } = {};

        for (const [key, value] of result) {
          if (value) {
            values[key] = value as unknown as T;
          }
        }

        return resolve(values);
      });
    });
  }

  /**
   * Get value from storage by keys.
   * @param key - key or keys.
   * @example
   * import { MobileStorage } from 'lib/storage'
   * const storage = new MobileStorage()
   * storage.get(key).then(recievePaylod => / Do something... /)
   */
  public get<T>(key: string): Promise<T | unknown> {
    return new Promise((resolve, reject) => {
      AsyncStorage.getItem(key, (err, result: T | unknown) => {
        if (err) {
          return reject(err);
        }

        return resolve(result);
      });
    });
  }

  public async getAll() {
    const keys = await this.getAllKeys();

    if (!keys || keys.length === 0) {
      return null;
    }

    return this.multiGet(...keys);
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
  public async rm(...keys: string[]): Promise<void> {
    await AsyncStorage.multiRemove(keys);
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