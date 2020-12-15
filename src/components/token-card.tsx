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

import { LoadSVG } from 'app/components/load-svg';

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
  canRemove: boolean;
  style?: ViewStyle;
  onPress?: () => void;
  onRemove?: (token: Token) => void;
};

export const TokenCard: React.FC<Prop> = ({
  token,
  net,
  rate,
  account,
  canRemove,
  currency,
  style,
  onPress = () => null,
  onRemove = () => null
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

  const handlePress = React.useCallback(() => {
    if (canRemove) {
      return onRemove(token);
    }

    return onPress();
  }, [canRemove, token, onRemove, onPress]);

  return (
    <TouchableOpacity
      style={[styles.container, style, {
        borderColor: canRemove && !token.default ? theme.colors.danger : theme.colors.gray
      }]}
      onPress={handlePress}
    >
      <View style={styles.header}>
        <Text style={styles.symbol}>
          {token.symbol}
        </Text>
        <LoadSVG
          height="30"
          width="30"
          url={`${TOKEN_ICONS}/${token.symbol}.svg`}
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
    borderWidth: 1
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
