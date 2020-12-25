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
  StyleSheet,
  ViewStyle
} from 'react-native';
import { theme } from 'app/styles';
import { useTheme } from '@react-navigation/native';

type Prop = {
  style?: ViewStyle;
};

export const Unselected: React.FC<Prop> = ({ style }) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.container, {
      borderColor: colors.primary
    }, style]}/>
  );
};

const styles = StyleSheet.create({
  container: {
    width: 28,
    height: 28,
    borderRadius: 100,
    borderWidth: 1,
    margin: 1
  }
});
