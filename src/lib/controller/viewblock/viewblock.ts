/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { API_KEY, VIEW_BLOCK_API_V1 } from 'app/config';
import { NetworkControll } from 'app/lib/controller/network';
import { ViewBlockMethods } from './methods';
import { TransactionType } from 'types';

export class ViewBlockControler {
  private _network: NetworkControll;
  private _options: RequestInit;

  constructor(network: NetworkControll) {
    this._network = network;
    this._options = {
      method: 'GET',
      headers: {
        'X-APIKEY': API_KEY
      }
    };
  }

  private get _netwrokParam() {
    return `network=${this._network.selected}`;
  }

  public async getAddress(address: string) {
    const params = `?${this._netwrokParam}`;
    const method = ViewBlockMethods.Addresses;
    const url = `${VIEW_BLOCK_API_V1}/${method}/${address}${params}`;
    const response = await fetch(url, this._options);

    return response.json();
  }

  public async getTransactions(address: string, page: number = 1): Promise<TransactionType[]> {
    const params = `?page=${page}&${this._netwrokParam}`;
    const method = ViewBlockMethods.Txns;
    const url = `${VIEW_BLOCK_API_V1}/${method}/${address}/${method}${params}`;
    const response = await fetch(url, this._options);
    const { docs } = await response.json();

    return docs;
  }
}
