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
  ScrollView,
  Alert,
  Text,
  RefreshControl
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';
import FastImage from 'react-native-fast-image';

import { BrwoserStackParamList } from 'app/navigator/browser';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';
import { keystore } from 'app/keystore';
import { DApp } from 'types';

type Prop = {
  navigation: StackNavigationProp<BrwoserStackParamList>;
  route: RouteProp<BrwoserStackParamList, 'BrowserApp'>;
};

export const BrowserAppPage: React.FC<Prop> = ({ route }) => {
  const { colors } = useTheme();

  return (
    <View>
      <ScrollView style={[styles.container, {
        backgroundColor: colors.card
      }]}>
        <View style={styles.titleContainer}>
          <FastImage
            source={{ uri: route.params.app.icon }}
            style={styles.icon}
          />
          <Text style={[styles.title, {
            color: colors.text
          }]}>
            {route.params.app.title}
          </Text>
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 15,
    borderTopRightRadius: 16,
    borderTopLeftRadius: 16,
    height: '100%',
    marginTop: 8,
    padding: 16
  },
  icon: {
    height: 50,
    width: 50,
    borderRadius: 100,
  },
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  title: {
    fontFamily: fonts.Bold,
    fontSize: 32
  }
});

export default BrowserAppPage;
