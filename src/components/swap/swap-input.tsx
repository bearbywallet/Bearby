/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2021 ZilPay
 */

import type { Token } from 'types';

import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  StyleSheet,
  ViewStyle,
  Dimensions,
  StyleProp
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import Big from 'big.js';

import { LoadSVG } from 'app/components/load-svg';
import ArrowIconSVG from 'app/assets/icons/arrow.svg';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';

import { fonts } from 'app/styles';
import { toBech32Address } from 'app/utils/bech32';
import { nFormatter, toConversion } from 'app/filters';

Big.PE = 99;

type Prop = {
  token: Token;
  net: string;
  value: string;
  title: string;
  currency: string;
  rate: number;
  disabled?: boolean;
  balance?: string;
  containerStyles?: StyleProp<ViewStyle>;
  pecrents?: number[];
  onChose?: () => void;
  onChange?: (value: string) => void;
};

const { width } = Dimensions.get('window');
export const SwapInput: React.FC<Prop> = ({
  token,
  net,
  value,
  title,
  rate,
  containerStyles,
  currency,
  balance = '0',
  disabled = false,
  pecrents = [0, 10, 25, 50, 70, 100],
  onChose = () => null,
  onChange = () => null
}) => {
  const { colors } = useTheme();

  const conversion = React.useMemo(() => {
    const tokenRate = rate * (token.rate || 0);
    const amount = Big(value).mul(10 ** token.decimals);

    return toConversion(String(amount), tokenRate, token.decimals);
  }, [token, rate, value]);

  const hanldeOnPercent = React.useCallback((percent: number) => {
    try {
      const amount = Big(balance).div(10 ** token.decimals);
      const hundred = Big('100');
      const nPercent = Big(percent);
      const nAmount = Big(amount);
      onChange(String(nAmount.mul(nPercent).div(hundred)));
    } catch {
      ///
    }
  }, [balance, token]);


  return (
    <View style={[styles.container, {
      backgroundColor: colors.card
    }, containerStyles]}>
      <Text style={[styles.inputTitle, {
        color: colors.notification
      }]}>
        {title}
      </Text>
      <View style={styles.inputWrapper}>
        <TextInput
          style={[styles.input, {
            color: colors.text
          }]}
          keyboardType={'numeric'}
          selectionColor={colors.notification}
          value={value}
          editable={!disabled}
          onChangeText={onChange}
        />
        <TouchableOpacity
          style={styles.iconWrapper}
          onPress={onChose}
        >
          <LoadSVG
            addr={toBech32Address(token.address[net])}
            height="30"
            width="30"
          />
          <Text style={[styles.symbol, {
            color: colors.primary
          }]}>
            {token.symbol}
          </Text>
          <ArrowIconSVG fill={colors.primary} />
        </TouchableOpacity>
      </View>
      <View style={styles.inputWrapper}>
        <Text style={[styles.inputTitle, {
          color: colors.notification
        }]}>
          {nFormatter(conversion)} {currency}
        </Text>
        <View style={styles.iconWrapper}>
          {pecrents.map((p, key) => (
            <Button
              key={key}
              title={`${p}%`}
              color={colors.primary}
              textStyle={styles.percent}
              onPress={() => hanldeOnPercent(p)}
            />
          ))}
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  input: {
    fontFamily: fonts.Demi,
    fontSize: 20,
    paddingVertical: 6,
    width: width - 150
  },
  container: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 10
  },
  inputWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  inputTitle: {
    fontFamily: fonts.Regular,
    fontSize: 12
  },
  iconWrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  symbol: {
    fontFamily: fonts.Bold,
    paddingHorizontal: 5
  },
  percent: {
    fontSize: width / 27,
    paddingHorizontal: 4
  }
});
