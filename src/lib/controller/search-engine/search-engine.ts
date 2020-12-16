/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import {
  searchEngineStore,
  searchEngineStoreUpdate,
  searchEngineStoreReset
} from './store';
import { STORAGE_FIELDS } from 'app/config';
import { buildObject, MobileStorage } from 'app/lib';
import { UnstoppableDomains } from 'app/lib/controller/unstoppabledomains';
import { SearchEngineStoreType } from 'types';
import { deppUnlink } from 'app/utils';

export class SearchController {
  public readonly store = searchEngineStore;
  private readonly _storage: MobileStorage;
  private readonly _ud: UnstoppableDomains;

  constructor(storage: MobileStorage, ud: UnstoppableDomains) {
    this._storage = storage;
    this._ud = ud;
  }

  public async reset() {
    searchEngineStoreReset();

    await this._update(this.store.get());
  }

  public async sync() {
    const data = await this._storage.get<string>(
      STORAGE_FIELDS.SEARCH_ENGINE
    );

    if (typeof data !== 'string') {
      return this.reset();
    }

    try {
      await this._update(JSON.parse(data));
    } catch {
      return this.reset();
    }
  }

  public async changeEngine(index: number) {
    if (index < 0) {
      throw new Error('index < 0');
    }

    const state = this.store.get();

    state.selected = index;

    return this._update(state);
  }

  public toggleDweb(value: boolean) {
    const state = this.store.get();

    state.dweb = value;

    return this._update(state);
  }

  public getURLSearchEngine(query: string) {
    const state = this.store.get();
    const searchEngine = state.identities[state.selected];

    return searchEngine.query.replace('%s', query);
  }

  /**
   * Returns a sanitized url, which could be a search engine url if
   * a keyword is detected instead of a url
   *
   * @param input - String corresponding to url input
   * @param searchEngine - Protocol string to append to URLs that have none
   * @param defaultProtocol - Protocol string to append to URLs that have none
   * @returns - String corresponding to sanitized input depending if it's a search or url
   */
  public async onUrlSubmit(input: string, defaultProtocol = 'https://') {
    input = input.toLowerCase();

    if (this.store.get().dweb) {
      const cryptoDomain = await this._ud.tryResolveDweb(input);

      if (cryptoDomain) {
        return cryptoDomain;
      }
    }
    // Check if it's a url or a keyword
    const res = input.match(/^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w.-]+)+[\w\-._~:/?#[\]@!&',;=.+]+$/g);

    if (res === null) {
      // Add exception for localhost
      if (!input.startsWith('http://localhost') && !input.startsWith('localhost')) {
        // In case of keywords we default to google search
        return this.getURLSearchEngine(escape(input));
      }
    }

    const hasProtocol = input.match(/^[a-z]*:\/\//);

    return hasProtocol ? input : `${defaultProtocol}${input}`;
  }

  private async _update(state: SearchEngineStoreType) {
    searchEngineStoreUpdate(deppUnlink(state));

    await this._storage.set(
      buildObject(STORAGE_FIELDS.SEARCH_ENGINE, state)
    );
  }
}
