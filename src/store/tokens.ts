/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain } from 'effector';
import { Token } from '../../types';

const TokenDomain = createDomain();
const initalState: Token[] = [];
const store = TokenDomain.store(initalState);

export default {
  store
};
