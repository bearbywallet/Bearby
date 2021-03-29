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
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ViewStyle,
  View
} from 'react-native';
import { categories } from './apps';
import { useTheme } from '@react-navigation/native';

import Social from 'app/assets/social.svg';
import Exchange from 'app/assets/exchange.svg';
import Finance from 'app/assets/finance.svg';
import Gambling from 'app/assets/gambling.svg';
import Games from 'app/assets/games.svg';
import HighRisk from 'app/assets/high-risk.svg';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  title: string;
  el: number;
  onPress?: () => void;
};
const { width } = Dimensions.get('window');
const Imgaes = [
  <Games
    width={width / 3}
    height={width / 7}
  />,
  <Finance
    width={width / 3}
    height={width / 7}
  />,
  <Social
    width={width / 3}
    height={width / 5}
  />,
  <HighRisk
    width={width / 3}
    height={width / 7}
  />,
  <Exchange
    width={width / 3}
    height={width / 5}
  />,
  <Gambling
    width={width / 3}
    height={width / 5}
  />,
];

export const BrowserCarditem: React.FC<Prop> = ({ el, title, style, onPress }) => {
  const { colors } = useTheme();

  return (
    <TouchableOpacity
      style={[styles.container, {
        backgroundColor: colors['card1']
      }, style]}
      onPress={onPress}
    >
      <View style={[StyleSheet.absoluteFill, styles.bgImage]}>
        {Imgaes[el]}
      </View>
      <Text style={[styles.title, {
        color: colors.text
      }]}>
        {title}
      </Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    minHeight: width / 5,
    minWidth: width / 2.5,
    borderRadius: 8,
    justifyContent: 'flex-end'
  },
  bgImage: {
    width: '100%',
    height: '100%',
    alignItems: 'flex-end',
    justifyContent: 'flex-end'
  },
  title: {
    fontSize: 17,
    fontFamily: fonts.Demi,
    padding: 10
  }
});
