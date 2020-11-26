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
  TouchableOpacity,
  StyleSheet,
  Text,
  ViewStyle
} from 'react-native';

import { theme } from 'app/styles';
import { TxStatsues } from 'app/config';

type Prop = {
  style?: ViewStyle;
  status: TxStatsues;
  onPress?: () => void;
};

export const TransactionItem: React.FC<Prop> = ({ status, style, onPress }) => {
  const statusColor = React.useMemo(() => {
    if (status === TxStatsues.pending) {
      return theme.colors.info;
    } else if (status === TxStatsues.rejected) {
      return theme.colors.danger;
    }

    return theme.colors.success;
  }, [status]);

  return (
    <TouchableOpacity
      style={[
        styles.container,
        style,
        { borderLeftColor: statusColor }
      ]}
      onPress={onPress}
    >
      <View style={styles.wrapper}>
        <Text style={styles.first}>
          Deployed
        </Text>
        <Text style={styles.first}>
          25,040 ZIL
        </Text>
      </View>
      <View style={styles.wrapper}>
        <Text style={styles.second}>
          15:00
        </Text>
        <Text style={styles.second}>
          $ 105,250
        </Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#2B2E33',
    padding: 7,
    margin: 5,
    borderRadius: 8,
    borderLeftWidth: 5,
    borderLeftColor: theme.colors.success
  },
  wrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  first: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  },
  second: {
    fontSize: 13,
    lineHeight: 17,
    color: '#8A8A8F',
    paddingTop: 3
  }
});
