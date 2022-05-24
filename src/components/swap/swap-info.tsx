/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2021 ZilPay
 */

import type { TokenValue } from 'types';

import React from 'react';
import {
  View,
  Text,
  StyleSheet
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import Big from 'big.js';

import i18n from 'app/lib/i18n';

import { fonts } from 'app/styles';
import { nFormatter } from 'app/filters';
import { keystore } from 'app/keystore';

Big.PE = 99;

type Prop = {
  pair: TokenValue[];
  currency: string;
  gasLimit: number;
  gasPrice: number;
  rate: number;
};

export const SwapInfo: React.FC<Prop> = ({ pair, currency, gasLimit, gasPrice, rate }) => {
  const { colors } = useTheme();

  const dexState = keystore.dex.store.useValue();

  const virtualParams = React.useMemo(() => {
    return keystore.dex.getVirtualParams(pair);
  }, [pair]);

  const afterSlippage = React.useMemo(() => {
    return keystore.dex.calcBigSlippage(pair[1].value, dexState.slippage);
  }, [pair, dexState]);

  const fee = React.useMemo(() => {
    return (gasPrice * gasLimit) / 10 ** 6;
  }, [gasLimit, gasPrice]);


  return (
    <View style={styles.container}>
      <View style={styles.row}>
        <Text style={[styles.key, {
          color: colors.notification
        }]}>
          {i18n.t('rate')}
        </Text>
        <Text style={[{
          color: colors.text
        }]}>
          1 {pair[0].meta.symbol} = {String(virtualParams.rate.round(9))} {pair[1].meta.symbol} <Text style={[styles.key, {
            color: colors.notification
          }]}>
            ({nFormatter(virtualParams.converted)}{currency})
          </Text>
        </Text>
      </View >
      <View style={styles.row}>
        <Text style={[styles.key, {
          color: colors.notification
        }]}>
          {i18n.t('txfee')}
        </Text>
        <Text style={[{
          color: colors.text
        }]}>
          {nFormatter(fee)} ZIL <Text style={[styles.key, {
            color: colors.notification
          }]}>
            ({nFormatter(fee * rate)}{currency})
          </Text>
        </Text>
      </View>
      <View style={styles.row}>
        <Text style={[styles.key, {
          color: colors.notification
        }]}>
          {i18n.t('price_impact')}
        </Text>
        <Text style={[{
          color: colors.text
        }]}>
          {String(virtualParams.impact)}%
        </Text>
      </View>
      <View style={styles.row}>
        <Text style={[styles.key, {
          color: colors.notification
        }]}>
          {i18n.t('after_slippage')}
        </Text>
        <Text style={[{
          color: colors.text
        }]}>
          {String(afterSlippage)} {pair[1].meta.symbol}
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 10
  },
  row: {
    paddingHorizontal: 10,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  key: {
    fontFamily: fonts.Regular
  },
  value: {
    fontFamily: fonts.Demi
  }
});
