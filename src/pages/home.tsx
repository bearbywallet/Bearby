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
  Text
} from 'react-native';
import { LogoSVG } from '../components';
import { SvgXml } from 'react-native-svg';

import { theme } from '../styles';

export const HomePage = () => {
  // const { colors } = useTheme();

  return (
    <View style={styles.container}>
      <View style={styles.top}>
        <SvgXml
          xml={LogoSVG}
          viewBox="50 0 300 200"
        />
        <View style={[StyleSheet.absoluteFill, styles.topContent]}>
          <Text>
            dasdsa
          </Text>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    backgroundColor: theme.colors.background
  },
  top: {
    width: '100%',
    height: '30%',
    alignItems: 'center',
    justifyContent: 'center'
  },
  topContent: {
    alignItems: 'center',
    justifyContent: 'center'
  }
});
