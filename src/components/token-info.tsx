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
import { Token } from 'types';
import { useTheme } from '@react-navigation/native';

import { LoadSVG } from 'app/components/load-svg';

import i18n from 'app/lib/i18n';
import { toLocaleString, toConversion, fromZil, nFormatter } from 'app/filters';
import { fonts } from 'app/styles';
import { keystore } from 'app/keystore';

export type Prop = {
  token: Token;
  currency: string;
  style?: ViewStyle;
};

export const TokenInfo: React.FC<Prop> = ({
  token,
  currency,
  style,
}) => {
  const settingsState = keystore.settings.store.useValue();
  const netwrokState = keystore.network.store.useValue();
  const tokensState = keystore.token.store.useValue();
  const { colors } = useTheme();
  const {
    balance,
    decimals,
    totalSupply,
    rate,
    symbol,
    name,
    address
  } = token;

  /**
   * ZIL(Default token) amount in float.
   */
  const amount = React.useMemo(
    () => fromZil(balance || '0', decimals),
    [balance, decimals]
  );
  const tokensSupply = React.useMemo(() => {
    const ts = fromZil(totalSupply || '0', decimals);

    return nFormatter(ts);
  }, [totalSupply, decimals]);
  /**
   * Converted to BTC/USD/ETH.
   */
  const conversion = React.useMemo(() => {
    const [ZIL] = tokensState;
    const r = settingsState.rate[ZIL.symbol] * (Number(rate) || 0);
    return toConversion(balance || '0', r, decimals);
  }, [rate, decimals, balance, tokensState, settingsState]);

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
          addr={address[netwrokState.selected]}
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
            {i18n.t('total_supply')}: {tokensSupply}
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
