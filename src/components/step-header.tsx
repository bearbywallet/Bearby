/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import {
  View,
  StyleSheet
} from 'react-native';
import { theme } from 'app/styles';

type Prop = {
  width: string;
};

export const StepHeader: React.FC<Prop> = ({ width }) => {
  return (
    <View style={[styles.container, { width }]} />
  );
};

const styles = StyleSheet.create({
  container: {
    height: 2,
    backgroundColor: theme.colors.primary,
    borderTopRightRadius: 10,
    borderBottomRightRadius: 10
  }
});
