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

import {
  AmountIconSVG
} from 'app/components/svg';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { fromZil, amountFromPercent } from 'app/filters';
import { Token } from 'types';

import styles from './styles';
import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  token: Token;
  netwrok: string;
  value: string;
  onChange: (amount: string) => void;
};

const percents = [0, 25, 50, 75, 100];
const { width } = Dimensions.get('window');
export const TransferAmount: React.FC<Prop> = ({
  style,
  token,
  netwrok,
  value,
  onChange
}) => {
  const balance = React.useMemo(
    () => token.balance[netwrok],
    [token, netwrok]
  );

  const handleChnage = React.useCallback((amount) => {
    onChange(Number(amount).toString());
  }, [onChange, token]);
  /**
   * Useing percents for calculate amount.
   */
  const handlePercentSelect = React.useCallback((percent) => {
    const newAmount = amountFromPercent(balance, percent);
    const zils = fromZil(newAmount, token.decimals, false);

    onChange(zils);
  }, [balance, onChange, token]);

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
          <SvgXml xml={AmountIconSVG} />
          <View style={styles.inputWrapper}>
            <TextInput
              style={commonStyles.input}
              keyboardType={'numeric'}
              placeholder={i18n.t('transfer_amount')}
              placeholderTextColor="#8A8A8F"
              value={value}
              onChangeText={handleChnage}
            />
            <Text>
              <Text style={[styles.nameAmountText, { color: '#8A8A8F' }]}>
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
              <Text style={styles.percent}>
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
    color: theme.colors.white,
    width: width - 80,
    padding: 10
  }
});
