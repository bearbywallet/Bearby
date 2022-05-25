/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { NIL_ADDRESS, UD_CONTRACT_ADDRESS } from 'app/config';
import { NetworkControll } from 'app/lib/controller/network';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { MobileStorage } from 'app/lib';
import { nameHash } from 'app/utils/namehash';
import { DomainResolver } from 'types';
import { fromBech32Address } from 'app/utils/bech32';
import { keystore } from 'app/keystore';

/**
 * Unstoppabledomains service domain resolver.
 * [more info](http://unstoppabledomains.com/)
 */
export class UnstoppableDomains {
  private _field = 'records';
  private _zilliqa: ZilliqaControl;
  private _netwrok: NetworkControll;

  constructor(storage: MobileStorage) {
    this._netwrok = new NetworkControll(storage, true);
    this._zilliqa = new ZilliqaControl(this._netwrok);
  }

  public async getAddressByDomain(domain: string): Promise<DomainResolver> {
    domain = String(domain).toLowerCase();

    const domainHash: string = nameHash(domain);
    const zilRecords = 'crypto.ZIL.address';
    const { records } = await this._zilliqa.getSmartContractSubState(
      UD_CONTRACT_ADDRESS,
      this._field,
      [domainHash]
    );

    const [owner, resolver] = records[domainHash].arguments;
    let address = null;

    if (resolver && resolver !== NIL_ADDRESS) {
      const result = await this._zilliqa.getSmartContractSubState(
        resolver,
        this._field,
        [zilRecords]
      );

      if (result && result[this._field][zilRecords]) {
        address = result[this._field][zilRecords];
      }

      try {
        address = fromBech32Address(address);
      } catch {
        ///
      }
    }

    return {
      owner,
      address,
      domain
    };
  }

  public async resolve(domain: string) {
    const domainHash = nameHash(domain);

    const { records } = await this._zilliqa.getSmartContractSubState(
      UD_CONTRACT_ADDRESS,
      this._field,
      [domainHash]
    );

    try {
      const [owner, resolver] = records[domainHash].arguments;

      if (!owner || !resolver || resolver === NIL_ADDRESS) {
        return null;
      }

      const result = await this._zilliqa.getSmartContractSubState(
        resolver,
        this._field
      );

      return result[this._field];
    } catch (err) {
      return null;
    }
  }

  public async tryResolveDweb(value: string) {
    const regex = /.*\w\.(zil|crypto|eth)/gm;

    if (!regex.test(value)) {
      return null;
    }

    const ipfs0 = 'ipfs.html.value';
    const ipfs1 = 'dweb.ipfs.hash';
    const ipfsr = 'ipfs.redirect_domain';
    const redirect = 'browser.redirect_url';

    try {
      const resolver = await this.resolve(value);
      const ipfsURL = keystore.ipfs.selected;

      if (resolver[ipfs0]) {
        return `${ipfsURL}/${resolver[ipfs0]}`;
      } else if (resolver[ipfs1]) {
        return `${ipfsURL}/${resolver[ipfs1]}`;
      } else if (resolver[ipfsr]) {
        return `${ipfsURL}/${resolver[ipfsr]}`;
      } else if (resolver[redirect]) {
        return `${ipfsURL}/${resolver[redirect]}`;
      }
    } catch {
      return null;
    }

    return null;
  }
}
