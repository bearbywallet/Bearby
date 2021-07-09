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
  Dimensions
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import FastImage from 'react-native-fast-image';

import { AccountMenu } from 'app/components/account-menu';
import { Button } from 'app/components/button';

import CreateBackground from 'app/assets/images/get_started_0.webp';

import I18n from 'app/lib/i18n';
import { Account, Token } from 'types';
import { fromZil, toConversion, nFormatter } from 'app/filters';
import { fonts } from 'app/styles';

type Prop = {
  account: Account;
  token: Token;
  netwrok: string;
  currency: string;
  rate: number;
  onCreateAccount: () => void;
  onReceive: () => void;
  onSend: () => void;
  onRemove: () => void;
};

const { width, height } = Dimensions.get('window');
export const HomeAccount: React.FC<Prop> = ({
  account,
  token,
  netwrok,
  rate,
  currency,
  onCreateAccount,
  onReceive,
  onSend,
  onRemove
}) => {
  const { colors } = useTheme();

  /**
   * ZIL(Default token) amount in float.
   */
  const amount = React.useMemo(
    () => fromZil(account.balance[netwrok][token.symbol], token.decimals),
    [token, account, netwrok]
  );
  /**
   * Converted to BTC/USD/ETH.
   */
  const conversion = React.useMemo(() => {
    const balance = account.balance[netwrok][token.symbol];

    return toConversion(balance, rate, token.decimals);
  }, [token, account, netwrok, rate]);

  return (
    <View style={styles.container}>
      <FastImage
        source={CreateBackground}
        style={styles.imageStyles}
      />
      <View style={[StyleSheet.absoluteFill, styles.content]}>
        <AccountMenu
          accountName={account.name}
          onCreate={onCreateAccount}
          onRemove={onRemove}
        />
        <View style={styles.amountWrapper}>
          <Text style={[styles.amount, {
            color: colors.text
          }]}>
            {nFormatter(amount)}
            <Text style={[styles.symbol, {
              color: colors.text
            }]}>
              {token.symbol}
            </Text>
          </Text>
          <Text style={[styles.convertedAmount, {
            color: colors.text
          }]}>
            {nFormatter(conversion)} {currency.toUpperCase()}
          </Text>
        </View>
        <View style={styles.buttons}>
          <View style={{
            flexDirection: 'row',
            alignItems: 'center'
          }}>
            <Button
              color={colors.primary}
              style={{
                marginRight: 5
              }}
              title={I18n.t('send')}
              onPress={onSend}
            />
            <View style={[styles.seporate, {
              backgroundColor: colors.notification
            }]}/>
            <Button
              color={colors.primary}
              style={{
                marginLeft: 5
              }}
              title={I18n.t('receive')}
              onPress={onReceive}
            />
          </View>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    height: height / 3,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: '5%'
  },
  content: {
    top: '10%',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: 15
  },
  amountWrapper: {
    alignItems: 'center'
  },
  amount: {
    fontSize: 40,
    fontFamily: fonts.Bold
  },
  imageStyles: {
    width: width + 100,
    height: height - 200,
    resizeMode: 'contain'
  },
  symbol: {
    fontSize: 17,
    fontFamily: fonts.Demi,
    fontWeight: 'normal'
  },
  convertedAmount: {
    fontSize: 13,
    fontFamily: 'Avenir'
  },
  buttons: {
    alignItems: 'center',
    width
  },
  seporate: {
    width: 1,
    height: 40
  }
});
