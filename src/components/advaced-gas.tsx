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
  TextInput,
  Button,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import { ArrowIconSVG } from 'app/components/svg';
import { GasSelector } from 'app/components/gas-selector';
import { Switcher } from 'app/components/switcher';

import { keystore } from 'app/keystore';
import { theme } from 'app/styles';
import { GasState } from 'types';
import i18n from 'app/lib/i18n';

type Prop = {
  style?: ViewStyle;
  gas: GasState;
  ds: boolean;
  onDSChanged: (value: boolean) => void;
  onChange: (gas: GasState) => void;
};

export const AdvacedGas: React.FC<Prop> = ({
  style,
  gas,
  ds,
  onDSChanged,
  onChange
}) => {
  const [isAdvanced, setIsAdvanced] = React.useState(false);

  return (
    <View
      style={[styles.container, style]}
    >
      <GasSelector
        style={{ backgroundColor: 'transparent' }}
        gasLimit={gas.gasLimit}
        gasPrice={gas.gasPrice}
        onChange={onChange}
      />
      <View style={styles.advanced}>
        <Button
          title={i18n.t('advanced_title')}
          color={theme.colors.primary}
          onPress={() => setIsAdvanced(!isAdvanced)}
        />
        <SvgXml
          xml={ArrowIconSVG}
          fill={theme.colors.primary}
          style={{ transform: [{ rotate: isAdvanced ? '-180deg' : '0deg' }]}}
        />
      </View>
      {isAdvanced ? (
        <React.Fragment>
          <Switcher
            enabled={ds}
            onChange={onDSChanged}
          >
            <Text style={styles.dsLabel}>
              {i18n.t('send_to_ds')}
            </Text>
          </Switcher>
          <View style={styles.inputWrapper}>
            <Text style={styles.gasLimitLabel}>
              {i18n.t('gas_limit')}:
            </Text>
            <TextInput
              style={styles.textInput}
              placeholderTextColor="#8A8A8F"
              defaultValue={gas.gasLimit}
              onChangeText={(gasLimit) => onChange({ ...gas, gasLimit })}
            />
          </View>
        </React.Fragment>
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 15
  },
  advanced: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'center'
  },
  dsLabel: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.white
  },
  gasLimitLabel: {
    fontSize: 16,
    lineHeight: 21,
    color: '#8A8A8F'
  },
  inputWrapper: {
    alignItems: 'center',
    marginVertical: 15
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    borderBottomColor: '#8A8A8F',
    borderBottomWidth: 1,
    color: theme.colors.white,
    width: '90%'
  },
});
