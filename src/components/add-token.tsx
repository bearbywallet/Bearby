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

export type Prop = {
  style?: ViewStyle;

  onSelect?: () => void;
};

export const AddToken: React.FC<Prop> = ({
  style,
  onSelect
}) => {

  return (
    <View
      style={[styles.container, style]}
      onTouchEnd={onSelect}
    >
      <View style={[styles.line, styles.line0]}/>
      <View style={styles.line}/>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 8,
    minHeight: 90,
    width: 180,
    backgroundColor: theme.colors.gray,
    padding: 10,
    borderWidth: 0.9,
    borderColor: theme.colors.gray,

    justifyContent: 'center',
    alignItems: 'center'
  },
  line: {
    width: 30,
    height: 3,
    backgroundColor: theme.colors.primary
  },
  line0: {
    transform: [{ rotate: '90deg' }]
  }
});
