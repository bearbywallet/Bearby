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
import { SvgXml } from 'react-native-svg';

import { OKIconSVG } from 'app/components/svg';
import { Unselected } from 'app/components/unselected';

import { theme } from 'app/styles';
import { trim } from 'app/filters';
import { Account } from 'types';

type Prop = {
  style?: ViewStyle;
  onPress?: (account: Account) => void;
  account: Account;
  selected: boolean;
  format: string;
};

export const AccountItem: React.FC<Prop> = ({
  selected,
  account,
  format,
  style,
  onPress = () => null
}) => (
  <TouchableOpacity
    style={[styles.accountItemWrapper, style]}
    onPress={() => onPress(account)}
  >
    <View>
      <Text style={styles.accountName}>
        {account.name}
      </Text>
      <Text style={styles.accountAddress}>
        {trim(account[format])}
      </Text>
    </View>
    {selected ? (
      <SvgXml xml={OKIconSVG}/>
    ) : (
      <Unselected />
    )}
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  accountName: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  },
  accountAddress: {
    color: '#8A8A8F',
    fontSize: 13,
    lineHeight: 17
  },
  accountItemWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 20,
    borderBottomColor: theme.colors.black,
    borderBottomWidth: 1
  }
});
