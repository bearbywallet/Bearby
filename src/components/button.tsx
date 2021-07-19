/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { fonts } from 'app/styles';
import React from 'react';
import {
  Text,
  StyleSheet,
  ViewStyle,
  TouchableOpacity,
  TextStyle
} from 'react-native';

type Prop = {
  color: string;
  title: string;
  disabled?: boolean;
  textStyle?: TextStyle;
  style?: ViewStyle | ViewStyle[];
  onPress?: () => void;
};

export const Button: React.FC<Prop> = ({
  style,
  title,
  disabled,
  color,
  onPress,
  textStyle = {}
}) => {
  return (
    <TouchableOpacity
      style={[style, {
        opacity: disabled ? 0.2 : 1
      }]}
      disabled={disabled}
      onPress={onPress}
    >
      <Text style={[styles.title, {
        ...textStyle,
        color
      }]}>
        {title}
      </Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 15
  },
  title: {
    textAlign: 'center',
    fontFamily: fonts.Demi,
    fontSize: 17,
    lineHeight: 22
  }
});
