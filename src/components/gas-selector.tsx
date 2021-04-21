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
  Text,
  StyleSheet,
  Alert,
  TouchableOpacity,
  Dimensions,
  ViewStyle
} from 'react-native';
import Big from 'big.js';
import { useTheme } from '@react-navigation/native';

import HelpIconSVG from 'app/assets/icons/help.svg';
import BigArrowIconSVG from 'app/assets/icons/big-arrow.svg';

import i18n from 'app/lib/i18n';
import { GasState } from 'types';
import { gasToFee, toLocaleString } from 'app/filters';
import { keystore } from 'app/keystore';
import { DEFAULT_GAS } from 'app/config';
import { fonts } from 'app/styles';

type Prop = {
  gasLimit: string;
  gasPrice: string;
  defaultGas: GasState;
  style?: ViewStyle;
  selectedColor: string;
  onChange?: (gas: GasState) => void;
};

Big.PE = 99;

const { width } = Dimensions.get('window');
export const GasSelector: React.FC<Prop> = ({
  style,
  gasLimit,
  gasPrice,
  defaultGas,
  selectedColor,
  onChange = () => null
}) => {
  const { colors, dark } = useTheme();
  const tokensState = keystore.token.store.useValue();

  const _1 = Big(1);
  const _2 = Big(2);
  const _3 = Big(3);

  const amountGas = (increse: number) => {
    const incresedGasPrice = Number(DEFAULT_GAS.gasPrice) * increse;
    const { fee } = gasToFee(gasLimit, String(incresedGasPrice));
    const [zilliqa] = tokensState;

    return `${toLocaleString(String(fee))} ${zilliqa.symbol}`;
  };

  const firstSelected = React.useMemo(
    () => Big(defaultGas.gasPrice).mul(_1).eq(gasPrice),
    [gasPrice, defaultGas]
  );
  const secondSelected = React.useMemo(
    () => Big(defaultGas.gasPrice).mul(_2).eq(gasPrice),
    [gasPrice, defaultGas]
  );
  const threeSelected = React.useMemo(
    () => Big(defaultGas.gasPrice).mul(_3).eq(gasPrice),
    [gasPrice, defaultGas]
  );

  const hanldeChangeGas = React.useCallback((amount: Big) => {
    onChange({
      gasLimit,
      gasPrice: Big(defaultGas.gasPrice).mul(amount).toString()
    });
  }, [gasPrice, gasLimit, onChange]);

  const createTwoButtonAlert = () =>
    Alert.alert(
      i18n.t('fee'),
      i18n.t('gas_price_description'),
      [
        { text: "OK" }
      ]
    );

  return (
    <View style={[styles.container, {
      backgroundColor: colors.card
    }, style]}>
      <View style={styles.header}>
        <Text style={[styles.title, {
          color: colors.border
        }]}>
          {i18n.t('fee')}
        </Text>
        <TouchableOpacity onPress={createTwoButtonAlert}>
          <HelpIconSVG fill={colors.border} />
        </TouchableOpacity>
      </View>
      <View style={styles.wrapper}>
        <TouchableOpacity
          style={[
            firstSelected ? { backgroundColor: selectedColor } : null,
            styles.item
          ]}
          onPress={() => hanldeChangeGas(_1)}
        >
          <View style={{ flexDirection: 'row' }}>
            <BigArrowIconSVG fill={colors.primary} />
            <BigArrowIconSVG fill={colors.notification} />
            <BigArrowIconSVG fill={colors.notification} />
          </View>
          <Text style={[styles.amount, {
            color: colors.text
          }]}>
            {amountGas(2)}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[
            secondSelected ? { backgroundColor: selectedColor } : null,
            styles.item
          ]}
          onPress={() => hanldeChangeGas(_2)}
        >
          <View style={{ flexDirection: 'row' }}>
            <BigArrowIconSVG fill={colors.primary} />
            <BigArrowIconSVG fill={colors.primary} />
            <BigArrowIconSVG fill={colors.notification} />
          </View>
          <Text style={[styles.amount, {
            color: colors.text
          }]}>
            {amountGas(3)}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[
            threeSelected ? { backgroundColor: selectedColor } : null,
            styles.item
          ]}
          onPress={() => hanldeChangeGas(_3)}
        >
          <View style={{ flexDirection: 'row' }}>
          <BigArrowIconSVG fill={colors.primary} />
            <BigArrowIconSVG fill={colors.primary} />
            <BigArrowIconSVG fill={colors.primary} />
          </View>
          <Text style={[styles.amount, {
            color: colors.text
          }]}>
            {amountGas(4)}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 16,
    alignItems: 'center'
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%'
  },
  title: {
    fontSize: 16,
    fontFamily: fonts.Demi
  },
  wrapper: {
    borderRadius: 8,
    padding: 5,
    marginTop: 10,
    justifyContent: 'space-between',
    alignItems: 'center',
    flexDirection: 'row',
    maxWidth: 400
  },
  item: {
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 4,
    borderRadius: 8,
    width: (width / 3) - 20,
    maxWidth: 100
  },
  amount: {
    fontSize: 13,
    lineHeight: 22,
    fontFamily: fonts.Regular
  }
});
