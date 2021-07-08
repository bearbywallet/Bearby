/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { createStackNavigator, StackNavigationOptions } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import {
  BrowserHomePage,
  WebViewPage,
  BrowserCategoryPage,
  BrowserAppPage
} from 'app/pages/browser';

import { DApp } from 'types';
import { URLType } from 'src/lib/controller/search-engine';

export type BrwoserStackParamList = {
  Browser: undefined;
  Category: {
    category: number;
  },
  Web: {
    params: URLType;
  };
  BrowserApp: {
    app: DApp;
  }
};

const BrowserStack = createStackNavigator<BrwoserStackParamList>();
export const browserNav: React.FC = () => {
  const { colors } = useTheme();
  const headerOptions: StackNavigationOptions = React.useMemo(() => ({
    headerTintColor: colors.text,
    headerStyle: {
      backgroundColor: colors.background,
      elevation: 0,
      shadowOpacity: 0
    },
    headerTitleStyle: {
      fontWeight: 'bold'
    }
  }), [colors]);

  return (
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
      <BrowserStack.Screen
        name="BrowserApp"
        component={BrowserAppPage}
        options={{
          ...headerOptions,
          title: ''
        }}
      />
    </BrowserStack.Navigator>
  );
};
