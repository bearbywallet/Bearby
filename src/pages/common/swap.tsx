/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2021 ZilPay
 */

import type { TokenValue } from 'types/store';

import React from 'react';
import Big from 'big.js';
import {
  StyleSheet,
  View
} from 'react-native';
import { RouteProp, useTheme } from '@react-navigation/native';

import { CustomButton } from 'app/components/custom-button';
import { SwapInput } from 'app/components/swap';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

import i18n from 'app/lib/i18n';
import { CommonStackParamList } from 'app/navigator/common';
import { keystore } from 'app/keystore';
import { deppUnlink } from 'app/utils/deep-unlink';


type Prop = {
  route: RouteProp<CommonStackParamList, 'SwapPage'>;
};

export const SwapPage: React.FC<Prop> = ({ route }) => {
  const { colors } = useTheme();

  const tokensState = keystore.token.store.useValue();
  const networkState = keystore.network.store.useValue();
  const accountState = keystore.account.store.useValue();
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();

  const [pair, setPair] = React.useState<TokenValue[]>([
    {
      value: '0',
      meta: tokensState[0],
      approved: Big(0)
    },
    {
      value: '0',
      meta: tokensState[1],
      approved: Big(0)
    }
  ]);

  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );


  const hanldeInput = React.useCallback((value: string) => {
    try {
      const newPair = deppUnlink<TokenValue[]>(pair);
      newPair[0].value = Boolean(value) ? Big(value).toString() : '0';

      const { amount } = keystore.dex.getRealAmount(newPair);

      newPair[1].value = String(amount);

      setPair(newPair);
    } catch {
      ///
    }
  }, [pair]);

  const hanldeOnChose = React.useCallback((index: number) => {
    // console.log(index);
  }, []);


  return (
    <KeyboardAwareScrollView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <View>
        <SwapInput
          token={pair[0].meta}
          currency={currencyState}
          rate={settingsState.rate[currencyState]}
          net={networkState.selected}
          value={pair[0].value}
          title={'You pay'}
          balance={account.balance[networkState.selected][pair[0].meta.symbol]}
          containerStyles={styles.input}
          onChange={hanldeInput}
          onChose={() => hanldeOnChose(0)}
        />
        <SwapInput
          token={pair[1].meta}
          currency={currencyState}
          rate={settingsState.rate[currencyState]}
          net={networkState.selected}
          value={pair[1].value}
          title={'you get'}
          pecrents={[]}
          disabled
          containerStyles={styles.input}
          onChose={() => hanldeOnChose(1)}
        />
      </View>
      <CustomButton
        title={i18n.t('swap')}
        style={styles.button}
      />
    </KeyboardAwareScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  input: {
    marginVertical: 5,
    margin: 10
  },
  button: {
    margin: 10
  }
});
