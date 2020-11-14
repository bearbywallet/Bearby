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
  StyleSheet
} from 'react-native';
import { theme } from 'app/styles';

type Prop = {
  index?: number;
};

export const Chip: React.FC<Prop> = ({ children, index }) => {
  return (
    <View style={styles.container}>
      {index && !isNaN(index) ? (
        <Text>
          {index}
        </Text>
      ) : null}
      <Text style={styles.text}>
        {children}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
  },
  text: {
    color: theme.colors.white
  }
});
