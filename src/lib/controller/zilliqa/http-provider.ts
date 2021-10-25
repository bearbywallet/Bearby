/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2021 ZilPay
 */
import type { Params, RPCBody } from 'types';

export class HttpProvider {
  private readonly _rpc = {
    id: 1,
    jsonrpc: '2.0'
  };

  public json(...rpcBody: RPCBody[]) {
    const body = rpcBody.length === 1 ?
      JSON.stringify(rpcBody[0]) : JSON.stringify(rpcBody);

    return {
      body,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    };
  }

  public buildBody(method: string, params: Params) {
    return {
      ...this._rpc,
      method,
      params
    };
  }
}
