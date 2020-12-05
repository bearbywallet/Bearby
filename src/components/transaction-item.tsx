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
import { TX_DIRECTION } from 'app/config';
import { Token, Transaction } from 'types';
import { fromZil, toLocaleString, toConversion } from 'app/filters';
import { fromBech32Address, tohexString } from 'app/utils';

type Prop = {
  style?: ViewStyle;
  status: number;
  tokens: Token[];
  rate: number;
  netwrok: string;
  currency: string;
  transaction: Transaction;
  onSelect: () => void;
};

export const TransactionItem: React.FC<Prop> = ({
  transaction,
  tokens,
  rate,
  currency,
  netwrok,
  style,
  onSelect
}) => {
  const token = React.useMemo(() => {
    const toAddressbase16 = fromBech32Address(transaction.to).toLowerCase();

    return tokens.find(
      (t) => t.address[netwrok] === toAddressbase16
    );
  }, [transaction, tokens, netwrok]);
  const statusColor = React.useMemo(() => {
    if (transaction.receiptSuccess) {
      return theme.colors.success;
    } else if (transaction.receiptSuccess === undefined) {
      return theme.colors.info;
    } else if (!transaction.receiptSuccess) {
      return theme.colors.danger;
    }

    return theme.colors.warning;
  }, [transaction]);
  const recipient = React.useMemo(() => {
    let t = '';
    let color = theme.colors.danger;

    if (transaction.direction === TX_DIRECTION.in) {
      t = '+';
    } else if (transaction.direction === TX_DIRECTION.out) {
      t = '-';
    }

    if (Number(transaction.value) === 0 && !token) {
      color = theme.colors.white;
      t = '';
    } else if (transaction.direction === TX_DIRECTION.in) {
      color = theme.colors.success;
    }

    return {
      t,
      color
    };
  }, [transaction, token]);
  const amount = React.useMemo(() => {
    const [zilliqa] = tokens;

    if (token && transaction.data) {
      const data = JSON.parse(transaction.data);
      const [_, amt] = data.params;
      const v = fromZil(amt.value, token.decimals);

      return {
        converted: 0,
        value: toLocaleString(v),
        symbol: token.symbol
      };
    }
    const value = fromZil(transaction.value, zilliqa.decimals);
    const converted = toConversion(transaction.value, rate, zilliqa.decimals);

    return {
      converted,
      value: toLocaleString(value),
      symbol: zilliqa.symbol
    };
  }, [transaction, tokens, rate, token]);
  const vname = React.useMemo(() => {
    if (typeof transaction.data === 'string') {
      try {
        const data = JSON.parse(transaction.data);

        if (!data._tag && Array.isArray(data)) {
          return 'Deployed';
        }

        return data._tag;
      } catch (err) {
        return 'Unexpected';
      }
    }

    return 'Payment';
  }, [transaction]);
  const time = React.useMemo(() => {
    const date = new Date(transaction.timestamp);

    return `${date.getHours()}:${date.getMinutes()}`;
  }, [transaction]);

  return (
    <TouchableOpacity
      style={[
        styles.container,
        style,
        { borderLeftColor: statusColor }
      ]}
      onPress={onSelect}
    >
      <View style={styles.wrapper}>
        <Text style={styles.first}>
          {vname}
        </Text>
        <Text style={[styles.first, { color: recipient.color }]}>
          {recipient.t}{amount.value} {amount.symbol}
        </Text>
      </View>
      <View style={styles.wrapper}>
        <Text style={styles.second}>
          {time}
        </Text>
        <Text style={styles.second}>
          {amount.converted} {currency.toUpperCase()}
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
