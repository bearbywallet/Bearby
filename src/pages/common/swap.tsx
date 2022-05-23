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
  StyleSheet,
  View
} from 'react-native';
import Big from 'big.js';
import { RouteProp, useTheme } from '@react-navigation/native';

import { SafeWrapper } from 'app/components/safe-wrapper';

import { CustomButton } from 'app/components/custom-button';
import { SwapInput } from 'app/components/swap';

import i18n from 'app/lib/i18n';
import { CommonStackParamList } from 'app/navigator/common';
import { keystore } from 'app/keystore';
import { deppUnlink } from 'app/utils/deep-unlink';


type Prop = {
  route: RouteProp<CommonStackParamList, 'SwapPage'>;
};

interface Pair {
  value: string;
  meta: Token
}

export const SwapPage: React.FC<Prop> = ({ route }) => {
  const { colors } = useTheme();

  const tokensState = keystore.token.store.useValue();
  const networkState = keystore.network.store.useValue();
  const accountState = keystore.account.store.useValue();
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();

  const [pair, setPair] = React.useState<Pair[]>([
    {
      value: '50',
      meta: tokensState[0]
    },
    {
      value: '0',
      meta: tokensState[1]
    }
  ]);

  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );


  const hanldeInput = React.useCallback((value: string) => {
    try {
      const newPair = deppUnlink<Pair[]>(pair);
      newPair[0].value = value;

      setPair(newPair);
    } catch {
      ////
    }
  }, [pair]);


  return (
    <SafeWrapper style={[styles.container, {
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
        />
      </View>
      <CustomButton title={i18n.t('swap')}/>
    </SafeWrapper>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 10
  },
  input: {
    marginVertical: 5
  }
});
