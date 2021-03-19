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
    padding: 10,
    borderRadius: 8,
    width: 70,
    height: 70
  },
  linkText: {
    fontSize: 10,
    fontFamily: fonts.Regular,
    textAlign: 'center'
  }
});
