/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import {
  BrowserHomePage,
  WebViewPage
} from 'app/pages/browser';

export type BrwoserStackParamList = {
  Browser: undefined;
  Web: {
    url: string;
  };
};

const BrowserStack = createStackNavigator<BrwoserStackParamList>();
export const browserNav: React.FC = () => (
  <BrowserStack.Navigator headerMode="none">
    <BrowserStack.Screen
      name="Browser"
      component={BrowserHomePage}
      options={{
        title: ''
      }}
    />
    <BrowserStack.Screen
      name="Web"
      component={WebViewPage}
      options={{
        title: ''
      }}
    />
  </BrowserStack.Navigator>
);
