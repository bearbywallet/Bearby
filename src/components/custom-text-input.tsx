/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { useTheme } from '@react-navigation/native';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';
import React from 'react';
import {
  TextInput,
  Text,
  StyleSheet,
  ViewStyle,
  View,
  Dimensions
} from 'react-native';
import { SvgXml } from 'react-native-svg';

type Prop = {
  style?: ViewStyle;
  defaultValue?: string;
  icon?: string;
  placeholder?: string;
  labelText?: string;
  secureTextEntry?: boolean;
  onChangeText?: ((text: string) => void);
};

const { width } = Dimensions.get('window');
export const CustomTextInput: React.FC<Prop> = ({
  icon,
  style,
  placeholder,
  defaultValue,
  labelText = '',
  secureTextEntry = false,
  onChangeText
}) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.inputWrapper, style]}>
      {icon ? (
        <SvgXml
          style={styles.icon}
          xml={icon}
          width={30}
        />
      ) : (
        <View style={styles.icon} />
      )}
      <View style={styles.wrapper}>
        <TextInput
          style={[styles.textInput, {
            color: colors.text,
            borderBottomColor: colors.border
          }]}
          defaultValue={defaultValue}
          secureTextEntry={secureTextEntry}
          placeholder={placeholder}
          placeholderTextColor={colors.notification}
          onChangeText={onChangeText}
        />
        <Text style={[styles.label, {
          color: colors.border
        }]}>
          {labelText}
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between'
  },
  wrapper: {
    width: width - 50,
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 5,
    marginRight: 16,
    fontFamily: fonts.Demi,
    borderBottomWidth: 1
  },
  label: {
    marginVertical: 5,
    maxWidth: width - 100,
    fontFamily: fonts.Regular
  },
  icon: {
    margin: 10
  }
});
