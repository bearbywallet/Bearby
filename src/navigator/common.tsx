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

import { CreateAccountPage } from 'app/pages/common';

import { headerOptions } from 'app/config';

export type CommonStackParamList = {
  CreateAccount: undefined;
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
  </CommonStack.Navigator>
);
