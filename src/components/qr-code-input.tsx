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
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import { QRScaner } from 'app/components/modals/qr-scaner';
import { QrcodeIconSVG } from 'app/components/svg';

import { colors, theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  label?: string;
  error?: string;
  placeholder?: string;
  value: string;
  onChange?: (address: string) => void;
};

const { width } = Dimensions.get('window');
export const QrCodeInput: React.FC<Prop> = ({
  style,
  label,
  value,
  error,
  placeholder,
  onChange = () => null
}) => {
  const [qrcodeModal, setQrcodeModal] = React.useState(false);

  const handleQrcode = React.useCallback((qrcode) => {
    const address = String(qrcode).replace('zilliqa://', '');

    onChange(address);
  }, [onChange]);

  return (
    <React.Fragment>
      <View style={[styles.container, style, {
        borderBottomColor: error ? theme.colors.danger : '#8A8A8F'
      }]}>
        <TextInput
          style={[styles.textInput, {
            color: error ? theme.colors.danger : theme.colors.white
          }]}
          placeholder={placeholder}
          value={value}
          placeholderTextColor="#8A8A8F"
          onSubmitEditing={() => null}
          onChangeText={onChange}
        />
        <TouchableOpacity onPress={() => setQrcodeModal(true)}>
          <SvgXml xml={QrcodeIconSVG}/>
        </TouchableOpacity>
      </View>
      <Text style={styles.error}>
        {error}
      </Text>
      <QRScaner
        visible={qrcodeModal}
        onTriggered={() => setQrcodeModal(false)}
        onScan={handleQrcode}
      />
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  container: {
    borderBottomWidth: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 10
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    width: width - 100
  },
  error: {
    fontSize: 13,
    lineHeight: 17,
    color: theme.colors.danger
  }
});
