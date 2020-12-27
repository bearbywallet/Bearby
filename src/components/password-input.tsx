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
import { useTheme } from '@react-navigation/native';
import { SvgXml } from 'react-native-svg';
import { LockSVG } from 'app/components/svg';

type Prop = {
  style?: ViewStyle;
  placeholder?: string;
  passwordError?: string;
  onChange: (password: string) => void;
  onSubmitEditing?: () => void
};

const { width } = Dimensions.get('window');
export const Passwordinput: React.FC<Prop> = ({
  style,
  placeholder,
  passwordError,
  onChange,
  onSubmitEditing = () => null
}) => {
  const { colors } = useTheme();

  return (
    <View style={style}>
      <View style={[styles.inputWrapper, {
        borderBottomColor: colors.border
      }]}>
        <SvgXml xml={LockSVG} />
        <TextInput
          style={[styles.textInput, {
            color: colors.text,
            borderBottomColor: colors.card
          }]}
          secureTextEntry={true}
          placeholder={placeholder}
          placeholderTextColor={colors.border}
          onChangeText={onChange}
          onSubmitEditing={onSubmitEditing}
        />
      </View>
      <Text style={[styles.errorMessage, {
        color: colors['danger']
      }]}>
        {passwordError}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    marginLeft: 15,
    borderBottomWidth: 1,
    width: width - 100
  },
  errorMessage: {
    marginTop: 4,
    lineHeight: 22
  }
});
