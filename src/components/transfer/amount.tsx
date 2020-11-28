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
  Dimensions,
  TextInput,
  ViewStyle
} from 'react-native';
import { SvgXml, SvgCssUri } from 'react-native-svg';

import {
  ArrowIconSVG,
  ReceiveIconSVG,
  WalletIconSVG
} from 'app/components/svg';
import { TokensModal } from 'app/components/modals';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { fromZil, amountFromPercent } from 'app/filters';
import { Token } from 'types';
import { TOKEN_ICONS } from 'app/config';

import styles from './styles';

type Prop = {
  style?: ViewStyle;
  token: Token;
  netwrok: string;
  value: string;
  onChange: (amount: string) => void;
};

const percents = [0, 25, 50, 75, 100];
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
    const numberic = Number(String(amount).replace(/[^0-9]/g, ''));

    onChange(String(numberic));
  }, [onChange]);
  /**
   * Useing percents for calculate amount.
   */
  const handlePercentSelect = React.useCallback((percent) => {
    const newAmount = amountFromPercent(balance, percent);

    onChange(newAmount);
  }, [balance, onChange]);

  return (
    <React.Fragment>
      <View style={[style, {
        marginTop: 30,
        padding: 15
      }]}>
        <View style={{
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'space-between'
        }}>
          <SvgXml xml={ReceiveIconSVG} />
          <View style={styles.inputWrapper}>
            <TextInput
              style={styles.textInput}
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
