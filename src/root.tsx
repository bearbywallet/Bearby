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
import { AppearanceProvider, useColorScheme } from 'react-native-appearance';

import Navigator from './navigator';
import { dark, light } from './styles';

const theme = {
  dark,
  light
};

export default function Root() {
  const scheme = useColorScheme();

  return (
    <AppearanceProvider>
      <NavigationContainer theme={theme[scheme]}>
        <SafeAreaProvider>
          <Navigator />
        </SafeAreaProvider>
        <StatusBar barStyle="default"/>
      </NavigationContainer>
    </AppearanceProvider>
  );
}
