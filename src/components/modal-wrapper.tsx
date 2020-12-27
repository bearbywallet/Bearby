/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { useTheme } from '@react-navigation/native';
import React from 'react';
import {
  View,
  StyleSheet,
  Dimensions,
  ViewStyle
} from 'react-native';

type Prop = {
  style?: ViewStyle;
};

const { height } = Dimensions.get('window');
export const ModalWrapper: React.FC<Prop> = ({ children, style }) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.container, style, {
      backgroundColor: colors.background
    }]}>
      {children}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 15,
    borderTopEndRadius: 16,
    borderTopStartRadius: 16,
    justifyContent: 'space-between',
    paddingVertical: 15,
    maxHeight: height - 20
  }
});
