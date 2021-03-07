/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { useTheme } from '@react-navigation/native';
import { fonts } from 'app/styles';
import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ViewStyle
} from 'react-native';

type Prop = {
  style?: ViewStyle;
  title: string;
};

export const LabelValue: React.FC<Prop> = ({ children, title, style }) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.txItem, style]}>
      <Text style={[styles.txLable, {
        color: colors.border
      }]}>
        {title}
      </Text>
      <Text style={[styles.txValue, {
        color: colors.text
      }]}>
        {children}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  txItem: {
    margin: 3
  },
  txLable: {
    fontSize: 14,
    fontFamily: fonts.Demi
  },
  txValue: {
    fontFamily: fonts.Regular,
    fontSize: 12
  }
});
