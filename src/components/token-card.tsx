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
  ViewStyle
} from 'react-native';
import { SvgCssUri } from 'react-native-svg';
import { Token } from 'types';
import { theme } from 'app/styles';
import { TOKEN_ICONS } from 'app/config';
import { toLocaleString, toConversion, fromZil } from 'app/filters';

export type Prop = {
  token: Token;
  net: string;
  rate: number;
  selected: boolean;
  style?: ViewStyle;

  onSelect: () => void;
};

export const TokenCard: React.FC<Prop> = ({
  token,
  net,
  rate,
  selected,
  style,
  onSelect
}) => {
  /**
   * ZIL(Default token) amount in float.
   */
  const amount = React.useMemo(
    () => fromZil(token.balance[net], token.decimals),
    [token.balance, net]
  );
  /**
   * Converted to BTC/USD/ETH.
   */
  const conversion = React.useMemo(() => {
    const balance = token.balance[net];

    return toConversion(balance, rate, token.decimals);
  }, [token.balance, net, rate]);

  return (
    <View
      style={[styles.container, style, (selected ? styles.selected : null)]}
      onTouchEnd={onSelect}
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
          ${toLocaleString(conversion)}
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 8,
    minHeight: 90,
    width: '45%',
    maxWidth: 150,
    backgroundColor: theme.colors.gray,
    padding: 10,
    borderWidth: 0.9,
    borderColor: theme.colors.gray
  },
  selected: {
    borderColor: theme.colors.primary
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
