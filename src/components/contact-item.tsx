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
  StyleSheet,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import { DeleteIconSVG } from 'app/components/svg';

import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  last?: boolean;
  name: string;
  bech32: string;
};

export const ContactItem: React.FC<Prop> = ({ style, name, bech32, last }) => (
  <View
    style={[styles.container, style]}
  >
    <Text style={styles.char}>
      A
    </Text>
    <View style={[styles.wrapper, { borderBottomWidth: last ? 0 : 1 }]}>
      <View>
        <Text style={styles.name}>
          {name}
        </Text>
        <Text style={styles.address}>
          {bech32}
        </Text>
      </View>
      <SvgXml xml={DeleteIconSVG} />
    </View>
  </View>
);

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingLeft: 15,
    backgroundColor: '#18191D'
  },
  wrapper: {
    width: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderBottomColor: '#09090C',
    paddingRight: 20,
    paddingVertical: 20,
    paddingLeft: 15
  },
  name: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  },
  address: {
    color: '#8A8A8F',
    fontSize: 13,
    lineHeight: 17
  },
  char: {
    color: '#666666',
    fontSize: 17,
    lineHeight: 22
  }
});
