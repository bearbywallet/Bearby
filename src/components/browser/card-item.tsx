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
import { useTheme } from '@react-navigation/native';
import FastImage from 'react-native-fast-image';

import Social from 'app/assets/images/2.webp';
import Exchange from 'app/assets/images/4.webp';
import Finance from 'app/assets/images/1.webp';
import Gambling from 'app/assets/images/5.webp';
import Games from 'app/assets/images/0.webp';
import HighRisk from 'app/assets/images/3.webp';

import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  title: string;
  el: number;
  onPress?: () => void;
};
const { width } = Dimensions.get('window');
const imageStyles = {
  width: 90,
  height: '100%',
  resizeMode: 'contain'
};
const Imgaes = [
  <FastImage
    source={Games}
    style={imageStyles}
  />,
  <FastImage
    source={Finance}
    style={imageStyles}
  />,
  <FastImage
    source={Social}
    style={imageStyles}
  />,
  <FastImage
    source={HighRisk}
    style={imageStyles}
  />,
  <FastImage
    source={Exchange}
    style={imageStyles}
  />,
  <FastImage
    source={Gambling}
    style={imageStyles}
  />
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
