/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { useTheme } from '@react-navigation/native';
import { fonts } from 'app/styles';
import React from 'react';
import {
  TextInput,
  ImagePropsBase,
  ViewProps,
  Text,
  StyleSheet,
  ViewStyle,
  View,
  Dimensions
} from 'react-native';

type Prop = {
  style?: ViewStyle;
  maxWidth?: number;
  defaultValue?: string;
  Icon?: React.FunctionComponent<ImagePropsBase | ViewProps>;
  placeholder?: string;
  labelText?: string;
  secureTextEntry?: boolean;
  onChangeText?: ((text: string) => void);
};

const { width } = Dimensions.get('window');
export const CustomTextInput: React.FC<Prop> = ({
  Icon,
  style,
  placeholder,
  defaultValue,
  maxWidth,
  labelText = '',
  secureTextEntry = false,
  onChangeText
}) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.inputWrapper, style]}>
      {Icon ? (
        <Icon
          style={styles.icon}
          width={30}
        />
      ) : (
        <View style={styles.icon} />
      )}
      <View style={styles.wrapper}>
        <TextInput
          style={[styles.textInput, {
            color: colors.text,
            borderBottomColor: colors.border,
            maxWidth
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
