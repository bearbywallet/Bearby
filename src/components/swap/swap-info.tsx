/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2021 ZilPay
 */

import type { Token } from 'types';

import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  StyleSheet,
  ViewStyle,
  Dimensions,
  StyleProp
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import Big from 'big.js';

import { LoadSVG } from 'app/components/load-svg';
import ArrowIconSVG from 'app/assets/icons/arrow.svg';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';

import { fonts } from 'app/styles';
import { toBech32Address } from 'app/utils/bech32';
import { nFormatter, toConversion } from 'app/filters';

Big.PE = 99;

type Prop = {
};

const { width } = Dimensions.get('window');
export const SwapInfo: React.FC<Prop> = () => {
  const { colors } = useTheme();

  return (
    <View style={styles.container}>

    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 10
  }
});
