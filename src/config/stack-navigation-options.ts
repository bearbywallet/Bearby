/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { StackNavigationOptions } from '@react-navigation/stack';

import { theme } from 'app/styles';

export const headerOptions: StackNavigationOptions = {
  headerTintColor: theme.colors.white,
  headerStyle: {
    backgroundColor: theme.colors.black
  },
  headerTitleStyle: {
    fontWeight: 'bold'
  }
}
