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
  Text,
  TouchableOpacity,
  StyleSheet,
  ViewStyle
} from 'react-native';
import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  title: string;
  disabled?: boolean;
  onPress?: () => void;
};

export const CustomButton: React.FC<Prop> = ({ title, disabled, style, onPress }) => {
  return (
    <TouchableOpacity
      style={[styles.container, style, {
        opacity: disabled ? 0.5 : 1
      }]}
      disabled={disabled}
      onPress={onPress}
    >
      <Text style={styles.text}>
        {title}
      </Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 8,
    paddingVertical: 11,
    borderRadius: 8,
    backgroundColor: theme.colors.primary,
    alignItems: 'center'
  },
  text: {
    color: theme.colors.black,
    fontSize: 17,
    lineHeight: 22
  }
});
