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
import { keystore } from 'app/keystore';

const theme = {
  dark,
  light
};

export default function Root() {
  const selected = keystore.theme.store.useValue();
  const iosScheme = useColorScheme();

  const scheme = React.useMemo(() => {
    if (!iosScheme) {
      return selected;
    } else if (!selected) {
      return 'dark';
    }

    return iosScheme;
  }, [iosScheme, selected]);


  return (
    <AppearanceProvider>
      <NavigationContainer theme={theme.dark}>
        <SafeAreaProvider>
          <Navigator />
        </SafeAreaProvider>
        <StatusBar barStyle={theme.dark.dark ? 'light-content' : 'dark-content'}/>
      </NavigationContainer>
    </AppearanceProvider>
  );
}
