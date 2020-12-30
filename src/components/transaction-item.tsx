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
import { useTheme } from '@react-navigation/native';

import { TX_DIRECTION } from 'app/config';
import { Token, TransactionType, Settings } from 'types';
import { fromZil, toLocaleString, toConversion } from 'app/filters';
import { fromBech32Address } from 'app/utils';

type Prop = {
  style?: ViewStyle;
  status: number;
  tokens: Token[];
  settings: Settings;
  netwrok: string;
  currency: string;
  transaction: TransactionType;
  onSelect: () => void;
};

export const TransactionItem: React.FC<Prop> = ({
  transaction,
  tokens,
  settings,
  currency,
  netwrok,
  style,
  onSelect
}) => {
  const { colors } = useTheme();

  const token = React.useMemo(() => {
    const toAddressbase16 = fromBech32Address(transaction.to).toLowerCase();

    return tokens.find(
      (t) => t.address[netwrok] === toAddressbase16
    );
  }, [transaction, tokens, netwrok]);
  const statusColor = React.useMemo(() => {
    if (transaction.receiptSuccess) {
      return colors['success'];
    } else if (transaction.receiptSuccess === undefined) {
      return colors['info'];
    } else if (!transaction.receiptSuccess) {
      return colors['danger'];
    }

    return colors['warning'];
  }, [transaction, colors]);
  const recipient = React.useMemo(() => {
    let t = '';
    let color = colors['danger'];

    if (transaction.direction === TX_DIRECTION.in) {
      t = '+';
    } else if (transaction.direction === TX_DIRECTION.out) {
      t = '-';
    } else if (transaction.direction === TX_DIRECTION.self) {
      t = '';
      color = colors['info'];
    }

    if (Number(transaction.value) === 0 && !token) {
      color = colors.text;
      t = '';
    } else if (transaction.direction === TX_DIRECTION.in) {
      color = colors['success'];
    }

    return {
      t,
      color
    };
  }, [colors, transaction, token]);
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
    const rate = token ? settings.rate[token.symbol] : 0;
    const converted = toConversion(transaction.value, rate, zilliqa.decimals);

    return {
      converted,
      value: toLocaleString(value),
      symbol: zilliqa.symbol
    };
  }, [transaction, tokens, settings, token]);
  const vname = React.useMemo(() => {
    if (transaction.data && typeof transaction.data === 'string') {
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
        {
          borderLeftColor: statusColor,
          backgroundColor: colors.background
        }
      ]}
      onPress={onSelect}
    >
      <View style={styles.wrapper}>
        <Text style={[styles.first, {
          color: colors.text
        }]}>
          {vname}
        </Text>
        <Text style={[styles.first, {
          color: recipient.color
        }]}>
          {recipient.t}{amount.value} {amount.symbol}
        </Text>
      </View>
      <View style={styles.wrapper}>
        <Text style={[styles.second, {
          color: colors.border
        }]}>
          {time}
        </Text>
        <Text style={[styles.second, {
          color: colors.border
        }]}>
          {amount.converted} {currency.toUpperCase()}
        </Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 7,
    margin: 5,
    borderRadius: 8,
    borderLeftWidth: 5
  },
  wrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  first: {
    fontSize: 17,
    lineHeight: 22
  },
  second: {
    fontSize: 13,
    lineHeight: 17,
    paddingTop: 3
  }
});
