/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { NetworkControll } from 'app/lib/controller/network';
import { JsonRPCCodes } from './codes';
import { Methods } from './methods';

import { tohexString } from 'app/utils/address';

type Params = string[] | number[] | (string | string[] | number[])[];

export class ZilliqaControl {
  private _network: NetworkControll;

  constructor(network: NetworkControll) {
    this._network = network;
  }

  /**
   * Getting account balance and nonce.
   * @param address - Account address in base16 format.
   */
  public async getBalance(address: string) {
    address = tohexString(address);

    const request = this._json(Methods.getBalance, [address]);
    const responce = await fetch(this._network.http, request);
    const data = await responce.json();

    if (data && data.result && data.result.balance) {
      return data.result;
    }

    if (data.error && data.error.code === JsonRPCCodes.AccountIsMotCreated) {
      return {
        balance: '0',
        nonce: 0
      };
    }

    throw new Error(data.error.message);
  }

  /**
   * Getting contract init(constructor).
   * @param contract - Contract address in base16 format.
   */
  public async getSmartContractInit(contract: string) {
    contract = tohexString(contract);

    const request = this._json(Methods.GetSmartContractInit, [contract]);
    const responce = await fetch(this._network.http, request);
    const data = await responce.json();

    if (data.error) {
      throw new Error(data.error.message);
    }

    return data.result;
  }

  /**
   * Get Field information of contract.
   * @param contract - Contract address in base16 format.
   * @param field - Field of smart contract.
   * @param params - Params of contract Map field.
   */
  public async getSmartContractSubState(
    contract: string,
    field: string,
    params: string[] | number[] = []
  ) {
    contract = tohexString(contract);

    const request = this._json(
      Methods.GetSmartContractSubState,
      [contract, field, params]
    );
    const responce = await fetch(this._network.http, request);
    const data = await responce.json();

    if (data.error) {
      throw new Error(data.error.message);
    }

    return data.result;
  }

  private _json(method: string, params: Params) {
    return {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        method,
        params,
        id: '1',
        jsonrpc: '2.0'
      }, null, '')
    };
  }
}
