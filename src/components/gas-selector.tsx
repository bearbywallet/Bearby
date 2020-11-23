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
  Dimensions,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import {
  BigArrowIconSVG,
  HelpIconSVG
} from 'app/components/svg';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { GasState } from 'types';
import { gasToFee } from 'app/filters';
import { keystore } from 'app/keystore';
import { useStore } from 'effector-react';
import { DEFAULT_GAS } from 'app/config';

type Prop = {
  gasLimit: string;
  gasPrice: string;
  onChange?: (gas: GasState) => void;
  style?: ViewStyle;
};

const { width } = Dimensions.get('window');
export const GasSelector: React.FC<Prop> = ({
  style,
  gasLimit,
  gasPrice,
  onChange = () => null
}) => {
  const tokensState = useStore(keystore.token.store);
  const amountGas = (increse: number) => {
    const incresedGasPrice = Number(DEFAULT_GAS.gasPrice) * increse;
    const { fee } = gasToFee(gasLimit, String(incresedGasPrice));
    const [zilliqa] = tokensState.identities;

    return `${fee} ${zilliqa.symbol}`;
  };

  const firstSelected = React.useMemo(
    () => DEFAULT_GAS.gasPrice === gasPrice,
    [gasPrice]
  );
  const secondSelected = React.useMemo(
    () => (Number(DEFAULT_GAS.gasPrice) * 2) === Number(gasPrice),
    [gasPrice]
  );
  const threeSelected = React.useMemo(
    () => (Number(DEFAULT_GAS.gasPrice) * 3) === Number(gasPrice),
    [gasPrice]
  );

  const createTwoButtonAlert = () =>
    Alert.alert(
      i18n.t('fee'),
      i18n.t('gas_price_description'),
      [
        { text: "OK" }
      ]
    );

  return (
    <View style={[styles.container, style]}>
      <View style={styles.header}>
        <Text style={styles.title}>
          {i18n.t('fee')}
        </Text>
        <View onTouchEnd={createTwoButtonAlert}>
          <SvgXml
            xml={HelpIconSVG}
            fill="#8A8A8F"
          />
        </View>
      </View>
      <View style={styles.wrapper}>
        <View
          style={[
            firstSelected ? { backgroundColor: '#2B2E33' } : null,
            styles.item
          ]}
          onTouchEnd={() => onChange({ gasLimit, gasPrice: DEFAULT_GAS.gasPrice })}
        >
          <View style={{ flexDirection: 'row' }}>
            <SvgXml
              xml={BigArrowIconSVG}
              fill={theme.colors.white}
            />
            <SvgXml
              xml={BigArrowIconSVG}
              fill="#666666"
            />
            <SvgXml
              xml={BigArrowIconSVG}
              fill="#666666"
            />
          </View>
          <Text style={styles.amount}>
            {amountGas(1)}
          </Text>
        </View>
        <View
          style={[
            secondSelected ? { backgroundColor: '#2B2E33' } : null,
            styles.item
          ]}
          onTouchEnd={() => onChange({ gasLimit, gasPrice: String(Number(DEFAULT_GAS.gasPrice) * 2) })}
        >
          <View style={{ flexDirection: 'row' }}>
            <SvgXml
              xml={BigArrowIconSVG}
              fill={theme.colors.white}
            />
            <SvgXml
              xml={BigArrowIconSVG}
              fill={theme.colors.white}
            />
            <SvgXml
              xml={BigArrowIconSVG}
              fill="#666666"
            />
          </View>
          <Text style={styles.amount}>
            {amountGas(2)}
          </Text>
        </View>
        <View
          style={[
            threeSelected ? { backgroundColor: '#2B2E33' } : null,
            styles.item
          ]}
          onTouchEnd={() => onChange({ gasLimit, gasPrice: String(Number(DEFAULT_GAS.gasPrice) * 3) })}
        >
          <View style={{ flexDirection: 'row' }}>
          <SvgXml
              xml={BigArrowIconSVG}
              fill={theme.colors.white}
            />
            <SvgXml
              xml={BigArrowIconSVG}
              fill={theme.colors.white}
            />
            <SvgXml
              xml={BigArrowIconSVG}
              fill={theme.colors.white}
            />
          </View>
          <Text style={styles.amount}>
            {amountGas(3)}
          </Text>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: theme.colors.gray,
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
    lineHeight: 21,
    color: '#8A8A8F'
  },
  wrapper: {
    borderWidth: 1,
    borderRadius: 8,
    padding: 5,
    marginTop: 10,
    borderColor: theme.colors.black,
    justifyContent: 'space-between',
    alignItems: 'center',
    flexDirection: 'row',
    maxWidth: 400,
    width: width - 20
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
    lineHeight: 17,
    color: theme.colors.white
  }
});
