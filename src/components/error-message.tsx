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
  Text,
  StyleSheet,
  ViewStyle
} from 'react-native';

type Prop = {
  style?: ViewStyle;
};

export const ErrorMessage: React.FC<Prop> = ({ children, style }) => {
  const { colors } = useTheme();

  return (
    <Text style={[styles.errorMessage , {
      color: colors['danger'],
      textShadowColor: colors['danger']
    }, style]}>
      {children}
    </Text>
  );
};

const styles = StyleSheet.create({
  errorMessage: {
    fontSize: 17,
    fontFamily: fonts.Demi,
    textAlign: 'center',
    textShadowOffset: {
      width: -1,
      height: 1
    },
    textShadowRadius: 1
  }
});
