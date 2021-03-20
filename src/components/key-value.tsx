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
  View,
  Text,
  StyleSheet
} from 'react-native';

type Prop = {
  title: string;
};

export const KeyValue: React.FC<Prop> = ({
  title,
  children
}) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.item, {
      borderColor: colors.primary
    }]}>
      <Text style={[styles.text, {
        color: colors.text
      }]}>
        {title}
      </Text>
      <Text style={{
        color: colors.text
      }}>
        {children}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  item: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    borderBottomWidth: 1,
    padding: 3
  },
  text: {
    fontFamily: fonts.Bold
  }
});
