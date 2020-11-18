/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain, createEvent } from 'effector';
import { DEFAULT_THEMES } from 'app/config';

export const themesStoreUpdate = createEvent<string>();
export const themesStoreReset = createEvent();

const ThemeDomain = createDomain();
const [initalState] = DEFAULT_THEMES;
export const themesStore = ThemeDomain
  .store<string>(initalState)
  .reset(themesStoreReset)
  .on(themesStoreUpdate, (_, value) => value);
