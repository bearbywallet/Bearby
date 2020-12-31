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
  Text,
  StyleSheet,
  ViewStyle,
  TouchableOpacity
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import { DeleteIconSVG } from 'app/components/svg';

import { SvgXml } from 'react-native-svg';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  onClose: () => void;
};

export const ModalTitle: React.FC<Prop> = ({ children, style, onClose }) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.container, style]}>
      <Text style={[styles.title, {
        color: colors.text
      }]}>
        {children}
      </Text>
      <TouchableOpacity onPress={onClose}>
        <SvgXml xml={DeleteIconSVG}/>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  title: {
    fontSize: 17,
    fontFamily: fonts.Demi
  }
});
