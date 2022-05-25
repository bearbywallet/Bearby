/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
export class Message {
  private _type: string;

  constructor(type: string) {
    this._type = type;
  }

  public serialize(payload: object | null, uuid?: string) {
    const msg = {
      type: this._type,
      payload: {
        uuid,
        ...payload
      }
    };

    return JSON.stringify(msg);
  }

  public reject(message = '', uuid?: string) {
    const msg = {
      type: this._type,
      payload: {
        uuid,
        reject: message
      }
    };

    return JSON.stringify(msg);
  }

  public resolve(payload: object | null, uuid?: string) {
    const msg = {
      type: this._type,
      payload: {
        uuid,
        resolve: payload
      }
    };

    return JSON.stringify(msg);
  }
}
