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

import { ArrowIconSVG } from 'app/components/svg';

import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
};

export const DropDownMenu: React.FC<Prop> = ({ children, style }) => {
  return (
    <View
      style={[styles.container, style]}
    >
      <View style={styles.wrapper}>
        <Text style={styles.title}>
          {children}
        </Text>
        <SvgXml
          style={{ marginLeft: 5 }}
          xml={ArrowIconSVG}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 10
  },
  wrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  title: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  }
});
