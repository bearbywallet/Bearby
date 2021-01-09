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
import { AppearanceProvider } from 'react-native-appearance';

import Navigator from './navigator';
import { theme } from './styles';
import { keystore } from 'app/keystore';

export default function Root() {
  const selected = keystore.theme.store.useValue();

  return (
    <AppearanceProvider>
      <NavigationContainer theme={theme[selected]}>
        <SafeAreaProvider>
          <Navigator />
        </SafeAreaProvider>
        <StatusBar barStyle={theme[selected].dark ? 'light-content' : 'dark-content'}/>
      </NavigationContainer>
    </AppearanceProvider>
  );
}
