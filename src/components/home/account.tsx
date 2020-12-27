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
  Button,
  Dimensions
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import { AccountMenu } from 'app/components/account-menu';
import CreateBackground from 'app/assets/logo.svg';

import I18n from 'app/lib/i18n';
import { Account, Token } from 'types';
import { fromZil, toConversion, nFormatter } from 'app/filters';

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
      <CreateBackground
        width={width + width / 2}
        height={width + width / 1.5}
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
          <Button
            color={colors.primary}
            title={I18n.t('send')}
            onPress={onSend}
          />
          <View style={[styles.seporate, {
            backgroundColor: colors.border
          }]}/>
          <Button
            color={colors.primary}
            title={I18n.t('receive')}
            onPress={onReceive}
          />
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    height: height / 4,
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
    fontSize: 44,
    fontFamily: 'Avenir',
    fontWeight: 'bold'
  },
  symbol: {
    fontSize: 17,
    fontFamily: 'Avenir',
    fontWeight: 'normal'
  },
  convertedAmount: {
    fontSize: 13,
    fontFamily: 'Avenir'
  },
  buttons: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    alignItems: 'center',
    width: 150,
    marginLeft: 20
  },
  seporate: {
    width: 1,
    height: 40
  }
});
