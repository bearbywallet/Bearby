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

import AuthLoadingPage from 'app/pages/auth-loading';

export type PreLoadingStackParamList = {
  AuthLoading: undefined;
};

const PreLoadingStack = createStackNavigator<PreLoadingStackParamList>();
export const PreLoading: React.FC = () => (
  <PreLoadingStack.Navigator>
    <PreLoadingStack.Screen
      name="AuthLoading"
      component={AuthLoadingPage}
      options={{
        header: () => null,
        title: ''
      }}
    />
  </PreLoadingStack.Navigator>
);
