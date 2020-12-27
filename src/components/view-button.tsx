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
  TouchableOpacity,
  Text,
  StyleSheet,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

type Prop = {
  style?: ViewStyle;
  icon: string;
  onPress?: () => void;
};

export const ViewButton: React.FC<Prop> = ({ icon, children, style, onPress }) => {
  const { colors } = useTheme();

  return (
    <TouchableOpacity
      style={[styles.linkItem, {
        backgroundColor: colors.card
      }, style]}
      onPress={onPress}
    >
      <SvgXml xml={icon}/>
      <Text style={[styles.linkText, {
        color: colors.text
      }]}>
        {children}
      </Text>
  </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  linkItem: {
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 15,
    borderRadius: 8,
    width: 80,
    height: 80
  },
  linkText: {
    fontSize: 10,
    lineHeight: 13,
    textAlign: 'center',
    marginTop: 5
  }
});
