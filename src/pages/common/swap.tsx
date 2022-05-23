/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2021 ZilPay
 */

import React from 'react';
import {
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import { SafeWrapper } from 'app/components/safe-wrapper';

import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const SwapPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();

  return (
    <SafeWrapper style={[styles.container, {
      backgroundColor: colors.background
    }]}>
    </SafeWrapper>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    borderTopEndRadius: 16,
    borderTopStartRadius: 16
  }
});
