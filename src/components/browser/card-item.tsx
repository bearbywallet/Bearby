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
import { theme } from 'app/styles';

import Social from 'app/assets/social.svg';
import Exchange from 'app/assets/exchange.svg';
import Finance from 'app/assets/finance.svg';
import Gambling from 'app/assets/gambling.svg';
import Games from 'app/assets/games.svg';
import HighRisk from 'app/assets/high-risk.svg';

type Prop = {
  style?: ViewStyle;
  title: string;
  el: string;
  onPress?: () => void;
};
const { width } = Dimensions.get('window');

const Imgaes = {
  [categories[0]]: <Games
    width={width / 3}
    height={width / 7}
  />,
  [categories[1]]: <Finance
    width={width / 3}
    height={width / 7}
  />,
  [categories[2]]: <Social
    width={width / 3}
    height={width / 5}
  />,
  [categories[3]]: <HighRisk
    width={width / 3}
    height={width / 7}
  />,
  [categories[4]]: <Exchange
    width={width / 3}
    height={width / 5}
  />,
  [categories[5]]: <Gambling
    width={width / 3}
    height={width / 5}
  />,
};

export const BrowserCarditem: React.FC<Prop> = ({ el, title, style, onPress }) => {
  return (
    <TouchableOpacity
      style={[styles.container, style]}
      onPress={onPress}
    >
      <View style={[StyleSheet.absoluteFill, styles.bgImage]}>
        {Imgaes[el]}
      </View>
      <Text style={styles.title}>
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
    backgroundColor: theme.colors.gray,
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
    lineHeight: 22,
    color: theme.colors.white,
    padding: 10
  }
});
