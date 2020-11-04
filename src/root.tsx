/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import * as React from 'react';
import { StatusBar } from 'react-native';

import { NavigationContainer } from '@react-navigation/native';

import Routers from './router';
import { WalletContext, wallet } from './keystore';
import { theme } from './styles';

export default function Root() {
  return (
    <WalletContext.Provider value={wallet}>
      <NavigationContainer theme={theme}>
        <StatusBar barStyle="light-content"/>
        <Routers />
      </NavigationContainer>
    </WalletContext.Provider>
  );
}
