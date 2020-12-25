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
import {
  View,
  Image,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ViewStyle
} from 'react-native';

type Prop = {
  style?: ViewStyle;
  title: string;
  icon: string;
  domain: string;
  onPress?: () => void;
};

const { width } = Dimensions.get('window');
export const BrowserAppItem: React.FC<Prop> = ({
  title,
  icon,
  domain,
  style,
  onPress
}) => {
  const { colors } = useTheme();

  return (
    <TouchableOpacity
      style={[styles.container, style, {
        backgroundColor: colors.card
      }]}
      onPress={onPress}
    >
      <Image
        style={styles.icon}
        source={{ uri: icon }}
      />
      <View>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {title}
        </Text>
        <Text style={[styles.domain, {
          color: colors.notification
        }]}>
          {domain}
        </Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 10,
    minHeight: width / 6,
    borderRadius: 8,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  title: {
    fontSize: 17,
    lineHeight: 22,
    textAlign: 'right'
  },
  icon: {
    height: 30,
    width: 30
  },
  domain: {
    fontSize: 15,
    lineHeight: 17,
    textAlign: 'right'
  }
});
