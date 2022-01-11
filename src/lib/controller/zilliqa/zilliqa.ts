/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import type { Params, RPCResponse, RPCBody, Token, SSN } from 'types';
import { NetworkControll } from 'app/lib/controller/network';
import { tokensStore } from 'app/lib/controller/tokens/state';
import { JsonRPCCodes } from './codes';
import { Methods } from './methods';
import { tohexString, toChecksumAddress } from 'app/utils/address';
import { Transaction } from '../transaction';
import {
  SSN_ADDRESS,
  ZILLIQA,
  ZILLIQA_KEYS,
  SCAM_TOKEN,
  DEFAULT_SSN
} from 'app/config';
import i18n from 'app/lib/i18n';
import { HttpProvider } from './http-provider';

type Balance = {
  nonce: number;
  balance: string;
};
export class ZilliqaControl {
  public provider = new HttpProvider();
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

    const body = this.provider.buildBody(Methods.getBalance, [address]);
    const request = this.provider.json(body);
    const responce = await fetch(this._network.http, request);

    if (responce.status !== 200) {
      throw new Error(i18n.t('node_error'));
    }

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

    const body = this.provider.buildBody(Methods.GetSmartContractInit, [contract]);
    const { result } = await this.sendJson(body);
    return result;
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

    const body = this.provider.buildBody(
      Methods.GetSmartContractSubState,
      [contract, field, params]
    );
    const { result } = await this.sendJson(body);
    return result;
  }

  public async getLatestTxBlock() {
    const body = this.provider.buildBody(Methods.GetLatestTxBlock, []);
    const { result } = await this.sendJson(body);
    return result;
  }

  public async getRecentTransactions() {
    const body = this.provider.buildBody(Methods.GetRecentTransactions, []);
    const { result } = await this.sendJson(body);
    return result;
  }

  public async getNetworkId() {
    const body = this.provider.buildBody(Methods.GetNetworkId, []);
    const { result } = await this.sendJson(body);

    return Number(result);
  }

  public async throughPxoy(method: string, params: Params): Promise<RPCResponse> {
    const body = this.provider.buildBody(method, params);
    try {
      if (method === Methods.GetTransactionStatus) {
        return await this.sendJsonNative(body);
      }

      return await this.sendJson(body);
    } catch (err) {
      return {
        ...body,
        error: {
          code: -0,
          data: null,
          message: String((err as Error).message)
        }
      };
    }
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

  public async send(tx: Transaction): Promise<{
    TranID: string;
    Info: string;
  }> {
    await this.detectSacmAddress(tx.toAddr);

    const body = this.provider.buildBody(
      Methods.CreateTransaction,
      [tx.self]
    );
    const request = this.provider.json(body);
    const responce = await fetch(this._network.http, request);
    const { error, result } = await responce.json();

    if (error && error.message) {
      throw new Error(error.message);
    }

    return result;
  }

  public async getMinimumGasPrice() {
    const body = this.provider.buildBody(Methods.GetMinimumGasPrice, []);
    const { result } = await this.sendJson(body);
    return result;
  }

  public async getSSnList(): Promise<SSN[]> {
    const [mainnet] = ZILLIQA_KEYS;
    if (this._network.selected !== mainnet) {
      throw new Error('SSn list allow on mainnet only');
    }
    const field = 'ssnlist';
    const contract = tohexString(SSN_ADDRESS[this._network.selected]);
    const http = ZILLIQA[this._network.selected].PROVIDER;

    const request = this.provider.json(this.provider.buildBody(
      Methods.GetSmartContractSubState,
      [contract, field, []]
    ));
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
        const body = this.provider.buildBody(
          Methods.GetNetworkId,
          []
        );
        const r = this.provider.json(body);
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

  public async sendJsonNative(...body: RPCBody[]) {
    const request = this.provider.json(...body);
    const responce = await fetch(this._network.nativeHttp, request);

    if (responce.status !== 200) {
      throw new Error(i18n.t('node_error'));
    }

    const data = await responce.json();

    if (Array.isArray(data)) {
      return data as RPCResponse[];
    }

    if (data.error) {
      throw new Error(data.error.message);
    }

    return data;
  }

  public async sendJson(...body: RPCBody[]) {
    const request = this.provider.json(...body);
    const responce = await fetch(this._network.http, request);

    if (responce.status !== 200) {
      throw new Error(i18n.t('node_error'));
    }

    const data = await responce.json();

    if (Array.isArray(data)) {
      return data as RPCResponse[];
    }

    if (data.error) {
      throw new Error(data.error.message);
    }

    return data;
  }
}
