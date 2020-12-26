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
import { useTheme } from '@react-navigation/native';
import { SvgXml } from 'react-native-svg';

import { ProfileSVG } from 'app/components/svg';

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
}) => {
  const { colors } = useTheme();

  return (
    <View style={style}>
    <View style={styles.inputWrapper}>
      <SvgXml xml={ProfileSVG} />
      <TextInput
        style={[styles.textInput, {
          borderBottomColor: colors.text,
          color: colors.text
        }]}
        autoCorrect={false}
        placeholder={i18n.t('pass_setup_input0')}
        defaultValue={name}
        placeholderTextColor={colors.card}
        onChangeText={setName}
      />
    </View>
    <Text style={[styles.label, {
      color: colors.border
    }]}>
      {i18n.t('pass_setup_label0')}
    </Text>
  </View>
  );
};

const styles = StyleSheet.create({
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    marginLeft: 15,
    borderBottomWidth: 1,
    width: width - 100
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  label: {
    marginVertical: 5,
    marginLeft: 38
  }
});
