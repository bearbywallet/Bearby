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
  TextInput,
  StyleSheet,
  Dimensions,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import { ProfileSVG } from 'app/components/svg';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';

type Prop = {
  style?: ViewStyle;
  name: string;
  setName: (name: string) => void;
};

const { width } = Dimensions.get('window');
export const AccountName: React.FC<Prop> = ({
  style,
  name,
  setName
}) => (
  <View style={style}>
  <View style={styles.inputWrapper}>
    <SvgXml xml={ProfileSVG} />
    <TextInput
      style={styles.textInput}
      placeholder={i18n.t('pass_setup_input0')}
      defaultValue={name}
      placeholderTextColor="#2B2E33"
      onChangeText={setName}
    />
  </View>
  <Text style={styles.label}>
    {i18n.t('pass_setup_label0')}
  </Text>
</View>
);

const styles = StyleSheet.create({
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    marginLeft: 15,
    borderBottomColor: '#2B2E33',
    borderBottomWidth: 1,
    color: theme.colors.white,
    width: width - 100
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  label: {
    marginVertical: 5,
    color: '#8A8A8F',
    marginLeft: 38
  }
});
