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

import { ContactsPage } from 'app/pages/settings/contacts';
import { ConnectionsPage } from 'app/pages/settings/connections';
import { AdvancedPage } from 'app/pages/settings/advanced';
import { AboutPage } from 'app/pages/settings/about';
import { SecurityPage } from 'app/pages/settings/security';
import { NetworkPage } from 'app/pages/settings/network';
import { GeneralPage } from 'app/pages/settings/general';
import { ExportPage } from 'app/pages/settings/export';

import { headerOptions, SecureTypes } from 'app/config';

export type SettingsStackParamList = {
  Contacts: undefined;
  Connections: undefined;
  About: undefined;
  Advanced: undefined;
  Security: undefined;
  Network: undefined;
  General: undefined;
  Export: {
    type: SecureTypes;
    content: string;
  }
};

const SettingsStack = createStackNavigator<SettingsStackParamList>();
export const Settings: React.FC = () => (
  <SettingsStack.Navigator>
    <SettingsStack.Screen
      name="Contacts"
      component={ContactsPage}
      options={{
        ...headerOptions,
        title: ''
      }}
    />
    <SettingsStack.Screen
      name="Export"
      component={ExportPage}
      options={{
        ...headerOptions,
        title: ''
      }}
    />
    <SettingsStack.Screen
      name="Connections"
      component={ConnectionsPage}
      options={{
        ...headerOptions,
        title: ''
      }}
    />
    <SettingsStack.Screen
      name="Advanced"
      component={AdvancedPage}
      options={{
        ...headerOptions,
        title: ''
      }}
    />
    <SettingsStack.Screen
      name="About"
      component={AboutPage}
      options={{
        ...headerOptions,
        title: ''
      }}
    />
    <SettingsStack.Screen
      name="Security"
      component={SecurityPage}
      options={{
        ...headerOptions,
        title: ''
      }}
    />
    <SettingsStack.Screen
      name="Network"
      component={NetworkPage}
      options={{
        ...headerOptions,
        title: ''
      }}
    />
    <SettingsStack.Screen
      name="General"
      component={GeneralPage}
      options={{
        ...headerOptions,
        title: ''
      }}
    />
  </SettingsStack.Navigator>
);
