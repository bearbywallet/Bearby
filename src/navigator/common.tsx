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
  CreateAccountPage,
  TransferPage
} from 'app/pages/common';

import { headerOptions } from 'app/config';
import i18n from 'app/lib/i18n';

export type CommonStackParamList = {
  CreateAccount: undefined;
  Transfer: {
    recipient?: string;
    selectedToken?: number;
  };
};

const CommonStack = createStackNavigator<CommonStackParamList>();
export const Common: React.FC = () => (
  <CommonStack.Navigator>
    <CommonStack.Screen
      name="CreateAccount"
      component={CreateAccountPage}
      options={{
        ...headerOptions,
        title: ''
      }}
    />
    <CommonStack.Screen
      name="Transfer"
      component={TransferPage}
      options={{
        ...headerOptions,
        title: i18n.t('transfer_title')
      }}
    />
  </CommonStack.Navigator>
);
