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
  Text,
  TouchableOpacity,
  StyleSheet,
  ViewStyle
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  last?: boolean;
  isChar?: boolean;
  name: string;
  bech32: string;
  onSelect?: () => void;
};

export const ContactItem: React.FC<Prop> = ({
  style,
  name,
  bech32,
  isChar,
  last,
  onSelect = () => null
}) => {
  const { colors } = useTheme();

  return (
    <TouchableOpacity
      style={[styles.container, style]}
      onPress={onSelect}
    >
      <Text style={[styles.char, {
        color: colors.notification
      }]}>
        {isChar ? name[0].toUpperCase() : ''}
      </Text>
      <View style={[styles.wrapper, {
        borderBottomWidth: last ? 0 : 1,
        borderBottomColor: colors.card,
      }]}>
        <View>
          <Text style={[styles.name, {
            color: colors.text
          }]}>
            {name}
          </Text>
          <Text style={[styles.address, {
            color: colors.border
          }]}>
            {bech32}
          </Text>
        </View>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  wrapper: {
    width: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingRight: 20,
    paddingVertical: 20,
    paddingLeft: 15
  },
  name: {
    fontFamily: fonts.Demi,
    fontSize: 17
  },
  address: {
    fontFamily: fonts.Regular,
    fontSize: 13
  },
  char: {
    fontFamily: fonts.Demi,
    fontSize: 17
  }
});
