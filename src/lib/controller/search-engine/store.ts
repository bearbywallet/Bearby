/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';
import { SearchEngineStoreType } from 'types';

const initalState: SearchEngineStoreType = {
  selected: 0,
  dweb: true,
  identities: [
    {
      name: 'DuckDuckGo',
      query: 'https://duckduckgo.com/?t=zilpay&q=%s'
    },
    {
      name: 'Google',
      query: 'http://www.google.com/search?q=%s'
    },
    {
      name: 'Yandex',
      query: 'https://yandex.ru/search/&text=%s'
    },
    {
      name: 'Bing',
      query: 'https://www.bing.com/search?q=%s'
    },
    {
      name: 'Yahoo',
      query: 'https://search.yahoo.com/search?p=%s'
    }
  ]
};
export const searchEngineStore = newRidgeState<SearchEngineStoreType>(initalState);

export function searchEngineStoreUpdate(payload: SearchEngineStoreType) {
  searchEngineStore.set(() => payload);
}
export function searchEngineStoreReset() {
  searchEngineStore.reset();
}
