/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { SvgXml } from 'react-native-svg';

import {
  HomeIconSVG,
  TimerIconSVG,
  BrowserIconSVG,
  SettingsIconSVG
} from 'app/components/svg';

import HomePage from 'app/pages/home';

import I18n from 'app/lib/i18n';
import { theme } from './styles';

const TabStack = createBottomTabNavigator();
const tabBarOptions = {
  activeTintColor: theme.colors.primary,
  activeColor: theme.colors.white,
  labelStyle: {
    fontSize: 12
  },
  inactiveTintColor: theme.colors.muted,
  style: {
    backgroundColor: theme.colors.gray
  }
};

export const TabNavigator: React.FC = () => {
  return (
    <TabStack.Navigator tabBarOptions={tabBarOptions}>
      <TabStack.Screen
        name="Home"
        component={HomePage}
        options={{
          tabBarLabel: I18n.t('home'),
          tabBarIcon: ({ color }) => (
            <SvgXml
              xml={HomeIconSVG}
              fill={color}
            />
          )
        }}
      />
    </TabStack.Navigator>
  );
};
