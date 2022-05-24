/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2021 ZilPay
 */

import type { TokenValue } from 'types';

import React from 'react';
import {
  View,
  Text,
  StyleSheet
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import ArrowIconSVG from 'app/assets/icons/arrow.svg';
import { Button } from 'app/components/button';
import { Indexer } from 'app/components/indexer';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { fonts } from 'app/styles';


type Prop = {
  slippage: number;
  blocks: number;
};

export const SwapAdvanced: React.FC<Prop> = ({ slippage, blocks }) => {
  const { colors } = useTheme();

  const [show, setShow] = React.useState(false);

  const hanldeSlippageChange = React.useCallback((v: number) => {
    keystore.dex.updateSlippage(v);
  }, []);

  const hanldeBlocksChange = React.useCallback((v: number) => {
    if (v > 1) {
      keystore.dex.updateSlippage(v);
    }
  }, []);

  return (
    <>
      <View style={styles.advanced}>
        <Button
          title={i18n.t('advanced_title')}
          color={colors.primary}
          style={styles.btn}
          onPress={() => setShow(!show)}
        />
        <ArrowIconSVG
          fill={colors.primary}
          style={{ transform: [{ rotate: show ? '-180deg' : '0deg' }]}}
        />
      </View>
      {show ? (
        <View style={styles.container}>
          <View style={styles.inputWrapper}>
            <Text style={[styles.inputTitle, {
              color: colors.notification
            }]}>
              Slippage
            </Text>
            <Indexer
              value={slippage}
              onChange={hanldeSlippageChange}
            />
          </View>
          <View style={styles.inputWrapper}>
            <Text style={[styles.inputTitle, {
              color: colors.notification
            }]}>
              Blocks
            </Text>
            <Indexer
              value={blocks}
              onChange={hanldeBlocksChange}
            />
          </View>
        </View>
      ) : null}
    </>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 10,
    width: '100%'
  },
  advanced: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  btn: {
    marginHorizontal: 5
  },
  inputWrapper: {
    marginVertical: 5
  },
  inputTitle: {
    fontFamily: fonts.Demi,
    fontSize: 13
  }
});
