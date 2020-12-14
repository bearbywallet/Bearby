/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { StatusBar } from 'react-native';

import { NavigationContainer } from '@react-navigation/native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import Navigator from './navigator';
import { theme } from './styles';

export default function Root() {
  return (
    <NavigationContainer theme={theme}>
      <SafeAreaProvider>
        <Navigator />
      </SafeAreaProvider>
      <StatusBar barStyle="light-content"/>
    </NavigationContainer>
  );
}
