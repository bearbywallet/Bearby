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
  Image,
  Text,
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ViewStyle
} from 'react-native';
import { theme } from 'app/styles';

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
  return (
    <TouchableOpacity
      style={[styles.container, style]}
      onPress={onPress}
    >
      <Image
        style={styles.icon}
        source={{ uri: icon }}
      />
      <View>
        <Text style={styles.title}>
          {title}
        </Text>
        <Text style={styles.domain}>
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
    backgroundColor: theme.colors.gray,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  title: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.white,
    textAlign: 'right'
  },
  icon: {
    height: 30,
    width: 30
  },
  domain: {
    fontSize: 15,
    lineHeight: 17,
    color: theme.colors.muted,
    textAlign: 'right'
  }
});
