/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain } from 'effector';
import { Settings } from 'types';
import { ZILLIQA, AddressFormats } from 'app/config';

const [mainnet] = Object.keys(ZILLIQA);
const SettingsDomain = createDomain();
const initalState: Settings = {
  netwrok: mainnet,
  config: ZILLIQA,
  blockNumber: 0,
  addressFormat: AddressFormats,
  rate: 0
};
const store = SettingsDomain.store(initalState);

export default {
  store
};
