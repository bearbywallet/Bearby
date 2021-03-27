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
import { useTheme } from '@react-navigation/native';

import { LoadSVG } from 'app/components/load-svg';

import i18n from 'app/lib/i18n';
import { toLocaleString, toConversion, fromZil } from 'app/filters';
import { fonts } from 'app/styles';
import { getIcon } from 'app/utils';

export type Prop = {
  decimals: number;
  balance?: string;
  symbol: string;
  address: string;
  name: string;
  rate: number;
  totalSupply?: string;
  currency: string;
  style?: ViewStyle;
};

export const TokenInfo: React.FC<Prop> = ({
  rate,
  symbol,
  decimals,
  address,
  name,
  currency,
  style,
  balance = '0',
  totalSupply = '0'
}) => {
  const { colors, dark } = useTheme();
  /**
   * ZIL(Default token) amount in float.
   */
  const amount = React.useMemo(
    () => fromZil(balance, decimals),
    [balance, decimals]
  );
  const tokensSupply = React.useMemo(
    () => fromZil(totalSupply, decimals),
    [totalSupply, decimals]
  );
  /**
   * Converted to BTC/USD/ETH.
   */
  const conversion = React.useMemo(() => {
    return toConversion(balance, rate, decimals);
  }, [rate, decimals, balance]);

  return (
    <View style={[styles.container, {
      backgroundColor: colors.card,
      borderColor: colors.card
    }, style]}>
      <View style={styles.header}>
        <View>
          <Text style={[styles.symbol, {
            color: colors.notification
          }]}>
            {symbol}
          </Text>
          <Text style={[styles.convertedAmount, {
            color: colors.text
          }]}>
            {name}
          </Text>
        </View>
        <LoadSVG
          height="30"
          width="30"
          url={getIcon(address, dark)}
        />
      </View>
      <View>
        <Text style={[styles.zilAmount, {
          color: colors.text
        }]}>
          {toLocaleString(amount)}
        </Text>
        <View style={{
          justifyContent: 'space-between',
          flexDirection: 'row'
        }}>
          <Text style={[styles.convertedAmount, {
            color: colors.notification
          }]}>
            {toLocaleString(conversion)} {currency.toUpperCase()}
          </Text>
          <Text style={[styles.convertedAmount, {
            color: colors.notification
          }]}>
            {i18n.t('total_supply')}: {toLocaleString(tokensSupply)}
          </Text>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 8,
    minHeight: 90,
    padding: 10,
    borderWidth: 0.9,
    height: 110
  },
  header: {
    width: '100%',
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  symbol: {
    fontSize: 17,
    fontFamily: fonts.Demi
  },
  zilAmount: {
    fontSize: 17,
    fontFamily: fonts.Bold
  },
  convertedAmount: {
    fontSize: 13,
    fontFamily: fonts.Regular
  }
});
