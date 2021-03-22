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

import { Token, StoredTx, Settings } from 'types';
import { fromZil, toLocaleString, toConversion } from 'app/filters';
import { fromBech32Address } from 'app/utils';
import { fonts } from 'app/styles';
import { StatusCodes } from 'app/lib/controller/transaction';

type Prop = {
  style?: ViewStyle;
  status: number;
  tokens: Token[];
  settings: Settings;
  netwrok: string;
  currency: string;
  transaction: StoredTx;
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
    const toAddressbase16 = transaction.toAddr.toLowerCase();

    return tokens.find(
      (t) => t.address[netwrok] === toAddressbase16
    );
  }, [transaction, tokens, netwrok]);

  const statusColor = React.useMemo(() => {
    switch (transaction.status) {
      case StatusCodes.Confirmed:
        return colors['success'];
      case StatusCodes.PendingAwait:
        return colors['success'];
      case StatusCodes.Pending:
        return colors['warning'];
      default:
        return colors['danger'];
    }
  }, [transaction, colors]);
  const recipient = React.useMemo(() => {
    let t = '-';
    let color = colors.text;

    if (Number(transaction.amount) === 0 && !token) {
      color = colors.text;
      t = '';
    }

    return {
      t,
      color
    };
  }, [colors, transaction, token]);
  const amount = React.useMemo(() => {
    const value = fromZil(transaction.amount, transaction.token.decimals);
    const rate = token ? settings.rate[token.symbol] : 0;
    const converted = toConversion(transaction.amount, rate, transaction.token.decimals);

    return {
      converted,
      value: toLocaleString(value),
      symbol: transaction.token.symbol
    };
  }, [transaction, tokens, settings, token]);
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
          backgroundColor: colors['card1']
        }
      ]}
      onPress={onSelect}
    >
      <View style={styles.wrapper}>
        <Text style={[styles.first, {
          color: colors.text
        }]}>
          {transaction.teg}
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
    fontSize: 14,
    fontFamily: fonts.Demi
  },
  second: {
    fontSize: 13,
    fontFamily: fonts.Regular,
    paddingTop: 3
  }
});
