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
  ViewStyle
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import { SvgXml } from 'react-native-svg';

import { ArrowIconSVG } from 'app/components/svg';
import { GasSelector } from 'app/components/gas-selector';
import { Switcher } from 'app/components/switcher';
import { Button } from 'app/components/button';

import { GasState } from 'types';
import i18n from 'app/lib/i18n';
import { deppUnlink } from 'app/utils';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  gas: GasState;
  ds: boolean;
  isDS: boolean;
  nonce: number;
  defaultGas: GasState;
  onDSChanged: (value: boolean) => void;
  onChange: (gas: GasState) => void;
  onChangeNonce: (nonce: number) => void;
};

export const AdvacedGas: React.FC<Prop> = ({
  style,
  gas,
  ds,
  isDS,
  nonce,
  defaultGas,
  onDSChanged,
  onChange,
  onChangeNonce
}) => {
  const { colors } = useTheme();
  const [isAdvanced, setIsAdvanced] = React.useState(false);

  return (
    <View
      style={[styles.container, style]}
    >
      <GasSelector
        style={{ backgroundColor: 'transparent' }}
        selectedColor={colors.card}
        gasLimit={gas.gasLimit}
        gasPrice={gas.gasPrice}
        defaultGas={deppUnlink(defaultGas)}
        onChange={onChange}
      />
      <View style={styles.advanced}>
        <Button
          title={i18n.t('advanced_title')}
          color={colors.primary}
          onPress={() => setIsAdvanced(!isAdvanced)}
        />
        <SvgXml
          xml={ArrowIconSVG}
          fill={colors.primary}
          style={{ transform: [{ rotate: isAdvanced ? '-180deg' : '0deg' }]}}
        />
      </View>
      {isAdvanced ? (
        <React.Fragment>
          <View style={[styles.inputWrapper, {
            borderBottomColor: colors.border
          }]}>
            <TextInput
              style={[styles.textInput, {
                color: colors.text
              }]}
              autoCorrect={false}
              placeholderTextColor={colors.border}
              defaultValue={gas.gasLimit}
              onChangeText={(gasLimit) => onChange({ ...gas, gasLimit })}
            />
            <Text style={[styles.gasLimitLabel, {
              color: colors.border
            }]}>
              {i18n.t('gas_limit')}
            </Text>
          </View>
                    <View style={[styles.inputWrapper, {
            borderBottomColor: colors.border
          }]}>
            <TextInput
              style={[styles.textInput, {
                color: colors.text
              }]}
              autoCorrect={false}
              placeholderTextColor={colors.border}
              defaultValue={String(nonce)}
              onChangeText={(n) => onChangeNonce(Number(n))}
            />
            <Text style={[styles.gasLimitLabel, {
              color: colors.border
            }]}>
              {i18n.t('nonce')}
            </Text>
          </View>
          {isDS ? (
            <Switcher
              enabled={ds}
              onChange={onDSChanged}
            >
              <Text style={[styles.dsLabel, {
                color: colors.text
              }]}>
                {i18n.t('send_to_ds')}
              </Text>
            </Switcher>
          ) : null}
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
    fontFamily: fonts.Demi
  },
  gasLimitLabel: {
    fontFamily: fonts.Regular,
    fontSize: 13
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginVertical: 10,
    borderBottomWidth: 1
  },
  textInput: {
    fontSize: 14,
    fontFamily: fonts.Demi,
    padding: 5,
    width: '50%'
  },
});
