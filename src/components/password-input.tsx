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
  Text,
  StyleSheet,
  ViewStyle,
  TextInput,
  Dimensions,
  View
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { LockSVG } from 'app/components/svg';

import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  placeholder?: string;
  passwordError?: string;
  onChange: (password: string) => void;
};

const { width } = Dimensions.get('window');
export const Passwordinput: React.FC<Prop> = ({
  style,
  placeholder,
  passwordError,
  onChange
}) => {
  return (
    <View style={style}>
      <View style={styles.inputWrapper}>
        <SvgXml xml={LockSVG} />
        <TextInput
          style={styles.textInput}
          secureTextEntry={true}
          placeholder={placeholder}
          placeholderTextColor="#2B2E33"
          onChangeText={onChange}
        />
        <Text style={styles.errorMessage}>
          {passwordError}
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
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
  errorMessage: {
    color: theme.colors.danger,
    marginTop: 4,
    lineHeight: 22
  }
});
