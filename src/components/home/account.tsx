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
import { LogoSVG } from '../svg';
import { SvgXml } from 'react-native-svg';

export const HomeAccount = () => {
  return (
    <View style={styles.container}>
      <SvgXml
        xml={LogoSVG}
        viewBox="50 0 300 200"
      />
      <View style={[StyleSheet.absoluteFill, styles.content]}>
        <Text>
          dasdsa
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    height: '30%',
    alignItems: 'center',
    justifyContent: 'center'
  },
  content: {
    alignItems: 'center',
    justifyContent: 'center'
  },
});
