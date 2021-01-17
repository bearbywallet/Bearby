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
  Text
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';

import { BrwoserStackParamList } from 'app/navigator/browser';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<BrwoserStackParamList>;
  route: RouteProp<BrwoserStackParamList, 'Category'>;
};

export const BrowserCategoryPage: React.FC<Prop> = ({ route }) => {
  const { colors } = useTheme();

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t(route.params.category)}
        </Text>
      </View>
      <View>
        <Text style={[styles.placeholder, {
          color: colors.notification
        }]}>
          {i18n.t('havent_apps')}
        </Text>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: 15
  },
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: '10%'
  },
  title: {
    fontSize: 30,
    fontFamily: fonts.Bold
  },
  placeholder: {
    fontSize: 16,
    fontFamily: fonts.Regular
  }
});

export default BrowserCategoryPage;
