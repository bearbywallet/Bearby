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
import { SvgXml } from 'react-native-svg';

import { OKIconSVG } from 'app/components/svg';
import { Unselected } from 'app/components/unselected';

import { trim } from 'app/filters';
import { Account } from 'types';

type Prop = {
  style?: ViewStyle;
  onPress?: (account: Account) => void;
  account: Account;
  last: boolean;
  selected: boolean;
  format: string;
};

export const AccountItem: React.FC<Prop> = ({
  selected,
  account,
  format,
  last,
  style,
  onPress = () => null
}) => {
  const { colors } = useTheme();

  return (
    <TouchableOpacity
      style={[styles.accountItemWrapper, style, {
        borderBottomWidth: last ? 0 : 1,
        borderBottomColor: colors.card
      }]}
      onPress={() => onPress(account)}
    >
      <View>
        <Text style={[styles.accountName, {
          color: colors.text
        }]}>
          {account.name}
        </Text>
        <Text style={[styles.accountAddress, {
          color: colors.text
        }]}>
          {trim(account[format])}
        </Text>
      </View>
      {selected ? (
        <SvgXml xml={OKIconSVG(colors.primary)}/>
      ) : (
        <Unselected />
      )}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  accountName: {
    fontSize: 17,
    lineHeight: 22
  },
  accountAddress: {
    fontSize: 13,
    lineHeight: 17
  },
  accountItemWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 20
  }
});
