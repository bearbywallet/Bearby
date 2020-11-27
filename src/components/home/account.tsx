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
import { SvgXml } from 'react-native-svg';

import { AccountMenu } from 'app/components/account-menu';
import { LogoSVG } from 'app/components/svg';

import { theme } from 'app/styles';
import I18n from 'app/lib/i18n';
import { Account, Token } from 'types';
import { fromZil, toConversion } from 'app/filters';

type Prop = {
  account: Account;
  token: Token;
  netwrok: string;
  currency: string;
  rate: number;
  onCreateAccount: () => void;
  onReceive: () => void;
  onSend: () => void;
};

const { width } = Dimensions.get('window');
export const HomeAccount: React.FC<Prop> = ({
  account,
  token,
  netwrok,
  rate,
  currency,
  onCreateAccount,
  onReceive,
  onSend
}) => {
  /**
   * ZIL(Default token) amount in float.
   */
  const amount = React.useMemo(
    () => fromZil(token.balance[netwrok], token.decimals),
    [token.balance, netwrok]
  );
  /**
   * Converted to BTC/USD/ETH.
   */
  const conversion = React.useMemo(() => {
    const balance = token.balance[netwrok];

    return toConversion(balance, rate, token.decimals);
  }, [token.balance, netwrok, rate]);

  return (
    <View style={styles.container}>
      <SvgXml
        xml={LogoSVG}
        width={width}
        viewBox="50 0 320 220"
      />
      <View style={[StyleSheet.absoluteFill, styles.content]}>
        <AccountMenu
          accountName={account.name}
          onCreate={onCreateAccount}
        />
        <View style={styles.amountWrapper}>
          <Text style={styles.amount}>
            {amount}
            <Text style={styles.symbol}>
              {token.symbol}
            </Text>
          </Text>
          <Text style={styles.convertedAmount}>
            {conversion} {currency.toUpperCase()}
          </Text>
        </View>
        <View style={styles.buttons}>
          <Button
            color={theme.colors.primary}
            title={I18n.t('send')}
            onPress={onSend}
          />
          <View style={styles.seporate}/>
          <Button
            color={theme.colors.primary}
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
    height: 300,
    alignItems: 'center',
    justifyContent: 'center'
  },
  content: {
    top: 0,
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: 15,
    paddingTop: 50
  },
  amountWrapper: {
    alignItems: 'center',
    // minHeight: 50
  },
  amount: {
    color: theme.colors.white,
    fontSize: 44,
    fontWeight: 'bold'
  },
  symbol: {
    fontSize: 17,
    fontWeight: 'normal',
    color: theme.colors.white
  },
  convertedAmount: {
    color: '#8A8A8F',
    fontSize: 13
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
    height: 40,
    backgroundColor: '#666666'
  }
});
