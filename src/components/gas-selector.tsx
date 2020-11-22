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
  Dimensions,
  TextInput,
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
import {
  gasToFee,
  fromZil
} from 'app/filters';
import { keystore } from 'app/keystore';
import { useStore } from 'effector-react';

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
  const amount = React.useMemo(() => {
    const fee = gasToFee(gasLimit, gasPrice);
    const [zilliqa] = tokensState.identities;

    return fromZil(fee, zilliqa.decimals);
  }, [tokensState, gasLimit, gasPrice]);

  return (
    <View style={[styles.container, style]}>
      <View style={styles.header}>
        <Text style={styles.title}>
          {i18n.t('fee')}
        </Text>
        <SvgXml
          xml={HelpIconSVG}
          fill="#8A8A8F"
        />
      </View>
      <View style={styles.wrapper}>
        <View style={styles.item}>
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
            {amount} ZIL
          </Text>
        </View>
        <View style={styles.item}>
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
            0.002 ZIL
          </Text>
        </View>
        <View style={styles.item}>
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
            0.002 ZIL
          </Text>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: theme.colors.gray
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
    flexDirection: 'row'
  },
  item: {
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 4,
    borderRadius: 8,
    backgroundColor: 'red',
    width: (width / 3) - 20
  },
  amount: {
    fontSize: 13,
    lineHeight: 17,
    color: theme.colors.white
  }
});
