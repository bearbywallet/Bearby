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
  WebViewPage,
  BrowserCategoryPage
} from 'app/pages/browser';
import { headerOptions } from 'app/config';

export type BrwoserStackParamList = {
  Browser: {
    url?: string;
  };
  Category: {
    category: string;
  },
  Web: {
    url: string;
  };
};

const BrowserStack = createStackNavigator<BrwoserStackParamList>();
export const browserNav: React.FC = () => (
  <BrowserStack.Navigator>
    <BrowserStack.Screen
      name="Browser"
      component={BrowserHomePage}
      options={{
        title: '',
        header: () => null
      }}
    />
    <BrowserStack.Screen
      name="Web"
      component={WebViewPage}
      options={{
        title: '',
        header: () => null
      }}
    />
    <BrowserStack.Screen
      name="Category"
      component={BrowserCategoryPage}
      options={{
        ...headerOptions,
        title: ''
      }}
    />
  </BrowserStack.Navigator>
);
