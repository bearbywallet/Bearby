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
import { useTheme } from '@react-navigation/native';

import HomeIconSVG from 'app/assets/icons/home.svg';
import TimerIconSVG from 'app/assets/icons/timer.svg';
import BrowserIconSVG from 'app/assets/icons/browser.svg';
import SettingsIconSVG from 'app/assets/icons/settings.svg';

import HomePage from 'app/pages/home';
import { browserNav, BrwoserStackParamList } from 'app/navigator/browser';
import { SettingsPage } from 'app/pages/settings';
import { HistoryPage } from 'app/pages/history';

import I18n from 'app/lib/i18n';

export type TabStackParamList = {
  Home: undefined;
  History: undefined;
  Browser: BrwoserStackParamList;
  Settings: undefined;
};

const TabStack = createBottomTabNavigator<TabStackParamList>();

export const TabNavigator: React.FC = () => {
  const { colors } = useTheme();
  const tabBarOptions = React.useMemo(() => ({
    activeTintColor: colors.primary,
    activeColor: colors.text,
    labelStyle: {
      fontSize: 12
    },
    inactiveTintColor: colors.notification,
    style: {
      borderTopColor: colors.card,
      backgroundColor: colors.card,
      elevation: 0,
      shadowOpacity: 0
    }
  }), [colors]);

  return (
    <TabStack.Navigator {...tabBarOptions}>
      <TabStack.Screen
        name="Home"
        component={HomePage}
        options={{
          tabBarLabel: I18n.t('home'),
          tabBarIcon: ({ color }) => (
            <HomeIconSVG fill={color} />
          )
        }}
      />
      <TabStack.Screen
        name="History"
        component={HistoryPage}
        options={{
          tabBarLabel: I18n.t('history'),
          tabBarIcon: ({ color }) => (
            <TimerIconSVG fill={color} />
          )
        }}
      />
      <TabStack.Screen
        name="Browser"
        component={browserNav}
        options={{
          tabBarLabel: I18n.t('browser'),
          tabBarIcon: ({ color }) => (
            <BrowserIconSVG fill={color}/>
          )
        }}
      />
      <TabStack.Screen
        name="Settings"
        component={SettingsPage}
        options={{
          tabBarLabel: I18n.t('settings'),
          tabBarIcon: ({ color }) => (
            <SettingsIconSVG fill={color} />
          )
        }}
      />
    </TabStack.Navigator>
  );
};
