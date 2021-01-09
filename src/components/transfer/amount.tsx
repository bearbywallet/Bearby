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
  TouchableOpacity,
  TextInput,
  StyleSheet,
  ViewStyle,
  Dimensions
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { useTheme } from '@react-navigation/native';
import Big from 'big.js';

import {
  AmountIconSVG
} from 'app/components/svg';

import i18n from 'app/lib/i18n';
import { fromZil, toQA } from 'app/filters';
import { Amount } from 'app/utils';
import { Token, Account, GasState } from 'types';

import styles from './styles';
import { fonts } from 'app/styles';

Big.PE = 99;

type Prop = {
  style?: ViewStyle;
  token: Token;
  account: Account;
  gas: GasState;
  netwrok: string;
  value: string;
  onChange: (amount: string) => void;
  onError?: (error: boolean) => void;
};

const percents = [0, 25, 50, 75, 100];
const { width } = Dimensions.get('window');
export const TransferAmount: React.FC<Prop> = ({
  style,
  token,
  gas,
  netwrok,
  account,
  value,
  onChange,
  onError = () => null
}) => {
  const { colors } = useTheme();
  const [error, setError] = React.useState(false);

  const balance = React.useMemo(
    () => account.balance[netwrok][token.symbol],
    [token, netwrok, account]
  );

  const handleChnage = React.useCallback((amount) => {
    if (isNaN(Number(amount))) {
      return null;
    }

    setError(false);

    try {
      const _amount = toQA(amount, token.decimals);
      const isInsufficientFunds = new Amount(gas, balance)
        .insufficientFunds(_amount, token);

      setError(isInsufficientFunds);
      onError(isInsufficientFunds);

      onChange(Big(amount).toString());
    } catch {
      onChange('0');
    }
  }, [onChange, token, gas, balance, onError]);
  /**
   * Useing percents for calculate amount.
   */
  const handlePercentSelect = React.useCallback((percent) => {
    if (isNaN(Number(balance)) ||  Number(balance) === 0) {
      return null;
    }

    setError(false);

    const amount = new Amount(gas, balance)
      .fromPercent(percent, token).toString();
    const zils = fromZil(amount, token.decimals, false);

    onChange(zils);
    onError(error);
  }, [balance, onChange, onError, token, gas]);

  return (
    <React.Fragment>
      <View style={[style, {
        marginTop: 30,
        padding: 15
      }]}>
        <View style={{
          flexDirection: 'row',
          alignItems: 'center'
        }}>
          <SvgXml
            xml={AmountIconSVG}
            height={20}
            width={30}
          />
          <View style={[styles.inputWrapper, {
            borderBottomColor: error ? colors['danger'] : colors.border
          }]}>
            <TextInput
              style={[commonStyles.input, {
                color: error ? colors['danger'] : colors.text
              }]}
              keyboardType={'numeric'}
              placeholder={i18n.t('transfer_amount')}
              placeholderTextColor={colors.border}
              value={value}
              onChangeText={handleChnage}
            />
            <Text style={{ minWidth: 50, textAlign: 'center' }}>
              <Text style={[styles.nameAmountText, {
                color: colors.border
              }]}>
                {token.symbol}
              </Text>
            </Text>
          </View>
        </View>
        <View style={styles.percentWrapper}>
          {percents.map((a, index) => (
            <TouchableOpacity
              key={index}
              onPress={() => handlePercentSelect(a)}
            >
              <Text style={[styles.percent, {
                color: colors.primary
              }]}>
                {a}%
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>
    </React.Fragment>
  );
};

const commonStyles = StyleSheet.create({
  input: {
    width: width - 100,
    fontFamily: fonts.Demi,
    fontSize: 17,
    padding: 5
  }
});
