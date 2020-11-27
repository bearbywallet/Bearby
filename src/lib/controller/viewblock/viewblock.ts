/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { VIEW_BLOCK_API, API_KEY } from 'app/config';
import { NetworkControll } from 'app/lib/controller/network';
import { Headers } from 'react-native-fs';

const methods = {
  addresses: 'addresses',
  txns: 'txs'
};

export class ViewBlockControler {
  private _network: NetworkControll;
  private _headers: Headers;

  constructor(network: NetworkControll) {
    this._network = network;
    this._headers = {
      'X-APIKEY': API_KEY
    };
  }

  public async getAddress(address: string) {
    const netwrok = this._network.selected;
    const params = `?network=${netwrok}`;
    const url = `${VIEW_BLOCK_API}/${methods.addresses}/${address}${params}`;
    const settings = {
      method: 'GET',
      headers: this._headers
    };
    const response = await fetch(url, settings);

    return response.json();
  }

  public async getTransactions(address: string, page: number = 1) {
    const netwrok = this._network.selected;
    const params = `?page=${page}&network=${netwrok}`;
    const url = `${VIEW_BLOCK_API}/${methods.addresses}/${address}/${methods.txns}${params}`;
    const settings = {
      method: 'GET',
      headers: this._headers
    };
    const response = await fetch(url, settings);

    return response.json();
  }
}
