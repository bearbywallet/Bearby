/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { useTheme } from '@react-navigation/native';
import { fonts } from 'app/styles';
import React from 'react';
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  View,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import { ArrowIconSVG } from 'app/components/svg';

type Prop = {
  style?: ViewStyle;
  icon: string;
  text: string;
  last: boolean;
  onPress?: () => void;
};

export const ListItem: React.FC<Prop> = ({
  style,
  icon,
  text,
  last,
  onPress
}) => {
  const { colors } = useTheme();

  return (
    <TouchableOpacity
      style={[styles.listItemWrapper, style]}
      onPress={onPress}
    >
      <SvgXml xml={icon} />
      <View style={[styles.listItem, {
        borderBottomColor: last ? 'transparent' : colors.notification
      }]}>
        <Text style={[styles.listTextItem, {
          color: colors.text
        }]}>
          {text}
        </Text>
        <SvgXml
          xml={ArrowIconSVG}
          fill={colors.notification}
          style={styles.arrow}
        />
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  listItemWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingLeft: 20
  },
  listItem: {
    width: '90%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderBottomWidth: 1,
    paddingVertical: 15
  },
  listTextItem: {
    fontFamily: fonts.Regular,
    fontSize: 17
  },
  arrow: {
    transform: [{ rotate: '-90deg'}],
    marginRight: 15
  }
});
