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
  StyleSheet,
  View,
  Alert,
  Text,
  RefreshControl
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';

import { BrwoserStackParamList } from 'app/navigator/browser';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';
import { ScrollView } from 'react-native-gesture-handler';
import { keystore } from 'app/keystore';
import { DApp } from 'types';

type Prop = {
  navigation: StackNavigationProp<BrwoserStackParamList>;
  route: RouteProp<BrwoserStackParamList, 'BrowserApp'>;
};

export const BrowserAppPage: React.FC<Prop> = () => {
  const { colors } = useTheme();

  return (
    <View>
    </View>
  );
};

const styles = StyleSheet.create({
});

export default BrowserAppPage;
