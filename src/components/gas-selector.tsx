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

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { GasState } from 'types';

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
}) => (
  <View style={[styles.container, style]}>
    <View style={{ width: width / 2 - 32 }}>
      <Text style={styles.textLable}>
        {i18n.t('gas_limit')}
      </Text>
      <TextInput
        style={styles.textInput}
        defaultValue={gasLimit}
        placeholderTextColor="#2B2E33"
        onChangeText={(value) => onChange({ gasPrice, gasLimit: value })}
      />
    </View>
    <View style={{ width: width / 2 - 32 }}>
      <Text style={styles.textLable}>
        {i18n.t('gas_price')}
      </Text>
      <TextInput
        defaultValue={gasPrice}
        style={styles.textInput}
        placeholderTextColor="#2B2E33"
        onChangeText={(value) => onChange({ gasLimit, gasPrice: value })}
      />
    </View>
  </View>
);

const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: theme.colors.gray,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  textLable: {
    color: '#8A8A8F',
    fontSize: 16,
    lineHeight: 21
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    borderBottomColor: '#2B2E33',
    borderBottomWidth: 1,
    color: theme.colors.white
  }
});
