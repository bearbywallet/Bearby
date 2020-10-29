/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import * as React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import Router from './router';
import { theme } from './styles';
import { StatusBar } from 'react-native';

export default function Root() {
  return (
    <NavigationContainer theme={theme}>
      <StatusBar barStyle="light-content"/>
      <Router />
    </NavigationContainer>
  );
}
