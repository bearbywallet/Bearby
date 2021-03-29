/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { useTheme } from '@react-navigation/native';
import URL from 'url-parse';
import {
  View,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ViewStyle,
  Text
} from 'react-native';
import FastImage from 'react-native-fast-image';
import { fonts } from 'app/styles';
import { DApp } from 'types';

type Prop = {
  app: DApp;
  style?: ViewStyle;
  onPress: () => void;
};

const { width } = Dimensions.get('window');
export const BrowserCategoryItem: React.FC<Prop> = ({
  app,
  style,
  onPress
}) => {
  const { colors } = useTheme();

  return (
    <TouchableOpacity
      style={[styles.container, {
        backgroundColor: colors.background
      }, style]}
      onPress={onPress}
    >
      <FastImage
        source={{ uri: app.icon }}
        style={[styles.icon, {
          backgroundColor: colors.card
        }]}
      />
      <View style={styles.wrapper}>
        <Text style={{
          fontFamily: fonts.Demi,
          color: colors.text,
          fontSize: 17
        }}>
          {app.title}
        </Text>
        <Text style={{
          fontFamily: fonts.Regular,
          color: colors.border,
          fontSize: 13
        }}>
          {new URL(app.url).host}
        </Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 8,
    width: '100%',
    height: 60,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-evenly'
  },
  wrapper: {
    justifyContent: 'space-between',
    minWidth: width / 2,
    height: 35
  },
  icon: {
    height: 40,
    width: 40,
    borderRadius: 100,
  }
});
