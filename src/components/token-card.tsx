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
  StyleSheet,
  Text,
  TouchableOpacity,
  ViewStyle
} from 'react-native';
import { SvgCssUri } from 'react-native-svg';
import { Token, Account } from 'types';
import { theme } from 'app/styles';
import { TOKEN_ICONS } from 'app/config';
import { toLocaleString, toConversion, fromZil } from 'app/filters';

export type Prop = {
  token: Token;
  account: Account;
  net: string;
  rate: number;
  currency: string;
  style?: ViewStyle;
  onPress?: () => void;
};

export const TokenCard: React.FC<Prop> = ({
  token,
  net,
  rate,
  account,
  currency,
  style,
  onPress = () => null
}) => {
  /**
   * ZIL(Default token) amount in float.
   */
  const amount = React.useMemo(
    () => fromZil(account.balance[net][token.symbol], token.decimals),
    [token, account, net]
  );
  /**
   * Converted to BTC/USD/ETH.
   */
  const conversion = React.useMemo(() => {
    const balance = account.balance[net][token.symbol];

    return toConversion(balance, rate, token.decimals);
  }, [token, account, net, rate]);

  return (
    <TouchableOpacity
      style={[styles.container, style]}
      onPress={onPress}
    >
      <View style={styles.header}>
        <Text style={styles.symbol}>
          {token.symbol}
        </Text>
        <SvgCssUri
          height="30"
          width="30"
          uri={`${TOKEN_ICONS}/${token.symbol}.svg`}
        />
      </View>
      <View>
        <Text style={styles.zilAmount}>
          {toLocaleString(amount)}
        </Text>
        <Text style={styles.convertedAmount}>
          {toLocaleString(conversion)} {currency.toUpperCase()}
        </Text>
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 8,
    minHeight: 90,
    width: '47%',
    backgroundColor: theme.colors.gray,
    padding: 10,
    borderWidth: 0.9,
    borderColor: theme.colors.gray
  },
  header: {
    width: '100%',
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  symbol: {
    color: theme.colors.muted,
    fontSize: 17
  },
  zilAmount: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22,
    fontWeight: 'bold'
  },
  convertedAmount: {
    color: theme.colors.muted,
    fontSize: 13
  }
});
