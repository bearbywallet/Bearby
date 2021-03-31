/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { NetworkControll } from 'app/lib/controller/network';
import { tokensStore } from 'app/lib/controller/tokens/state';
import { JsonRPCCodes } from './codes';
import { Methods } from './methods';
import { Token, TxParams, SSN } from 'types';
import { tohexString } from 'app/utils/address';
import { Transaction } from '../transaction';
import { toChecksumAddress } from 'app/utils';
import {
  SSN_ADDRESS,
  ZILLIQA,
  ZILLIQA_KEYS,
  SCAM_TOKEN,
  DEFAULT_SSN
} from 'app/config';

type Params = TxParams[] | string[] | number[] | (string | string[] | number[])[];
type Balance = {
  nonce: number;
  balance: string;
};
export class ZilliqaControl {
  private _network: NetworkControll;

  constructor(network: NetworkControll) {
    this._network = network;
  }

  /**
   * Getting account balance and nonce.
   * @param address - Account address in base16 format.
   */
  public async getBalance(address: string): Promise<Balance> {
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

  public async handleBalance(address: string, token: Token) {
    address = String(address).toLowerCase();

    const [zilliqa] = tokensStore.get();
    const net = this._network.selected;

    if (token.symbol === zilliqa.symbol) {
      const result = await this.getBalance(address);

      return result.balance;
    }

    if (!token.address[net]) {
      return '0';
    }

    const field = 'balances';
    const res = await this.getSmartContractSubState(
      token.address[net],
      field,
      [address]
    );

    if (!res || !res[field] || !res[field][address]) {
      return '0';
    }

    return res[field][address];
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

  public async getLatestTxBlock() {
    const request = this._json(Methods.GetLatestTxBlock, []);
    const responce = await fetch(this._network.http, request);
    const data = await responce.json();

    if (data.error) {
      throw new Error(data.error.message);
    }

    return data.result;
  }

  public async getRecentTransactions() {
    const request = this._json(Methods.GetRecentTransactions, []);
    const responce = await fetch(this._network.http, request);
    const data = await responce.json();

    if (data.error) {
      throw new Error(data.error.message);
    }

    return data.result;
  }

  public async getNetworkId() {
    const request = this._json(Methods.GetNetworkId, []);
    const responce = await fetch(this._network.http, request);
    const data = await responce.json();

    if (data.error) {
      throw new Error(data.error.message);
    }

    return Number(data.result);
  }

  public async throughPxoy(method: string, params: Params) {
    const request = this._json(method, params);
    const responce = await fetch(this._network.http, request);

    return responce.json();
  }

  public async detectSacmAddress(address: string) {
    const field = 'balances';
    let isScam = false;

    address = toChecksumAddress(address).toLowerCase();

    try {
      const result = await this.getSmartContractSubState(
        SCAM_TOKEN,
        field,
        [address]
      );

      if (result && result[field] && result[field][address]) {
        isScam = Number(result[field][address]) > 0;
      }

    } catch {
      //
    }

    if (isScam) {
      throw new Error('Scam detected');
    }
  }

  public async send(tx: Transaction): Promise<string> {
    await this.detectSacmAddress(tx.toAddr);

    const request = this._json(Methods.CreateTransaction, [
      tx.self
    ]);
    const responce = await fetch(this._network.http, request);
    const { error, result } = await responce.json();

    if (error && error.message) {
      throw new Error(error.message);
    }

    if (result && result.TranID) {
      return result.TranID;
    }

    throw new Error('Netwrok fail');
  }

  public async getTransactionStatus(hash: string) {
    hash = tohexString(hash);

    const request = this._json(Methods.GetTransactionStatus, [hash]);
    const responce = await fetch(this._network.http, request);
    const data = await responce.json();

    if (data.error) {
      throw new Error(data.error.message);
    }

    return data.result;
  }

  public async getTransaction(hash: string) {
    hash = tohexString(hash);

    const request = this._json(Methods.GetTransaction, [hash]);
    const responce = await fetch(this._network.http, request);
    const data = await responce.json();

    if (data.error) {
      throw new Error(data.error.message);
    }

    return data.result;
  }

  public async getSSnList(): Promise<SSN[]> {
    const custom = ZILLIQA_KEYS[ZILLIQA_KEYS.length - 1];
    if (this._network.selected === custom) {
      throw new Error('SSn list allow on mainnet and testnet only');
    }
    const field = 'ssnlist';
    const contract = tohexString(SSN_ADDRESS[this._network.selected]);
    const http = ZILLIQA[this._network.selected].PROVIDER;

    const request = this._json(
      Methods.GetSmartContractSubState,
      [contract, field, []]
    );
    const responce = await fetch(http, request);
    const data = await responce.json();

    if (data.error) {
      throw new Error(data.error.message);
    }

    const ssnlist = data.result[field];
    const list = Object.keys(ssnlist).map((addr) => ({
      address: addr,
      name: ssnlist[addr].arguments[3],
      api: ssnlist[addr].arguments[5]
    }));
    const defaultSSn: SSN = {
      address: '',
      name: DEFAULT_SSN,
      api: http,
      ok: true,
      id: 1,
      time: 0
    };
    const ssnList = [defaultSSn, ...list].map(async(ssn) => {
      const t0 = performance.now();
      try {
        const r = this._json(
          Methods.GetNetworkId,
          []
        );
        const res = await fetch(ssn.api, r);
        const { error, result } = await res.json();

        if (error) {
          throw new Error(error.message);
        }

        const id = Number(result);
        const t1 = performance.now();

        return {
          ...ssn,
          id,
          time: t1 - t0,
          ok: res.ok
        };
      } catch {
        const t1 = performance.now();
        return {
          ...ssn,
          id: 0,
          time: t1 - t0,
          ok: false
        };
      }
    });
    const gotSSN = await Promise.all(ssnList);

    return gotSSN.filter((ssn) => ssn.ok);
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
        id: 1,
        jsonrpc: '2.0'
      })
    };
  }
}
