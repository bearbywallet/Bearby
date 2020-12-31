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
  ActivityIndicator,
  StyleSheet,
  Dimensions,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { useTheme } from '@react-navigation/native';

import { QRScaner } from 'app/components/modals/qr-scaner';
import { QrcodeIconSVG } from 'app/components/svg';

import { keystore } from 'app/keystore';
import { toBech32Address } from 'app/utils';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  error?: string;
  placeholder?: string;
  value: string;
  zns?: boolean;
  onChange?: (address: string) => void;
  onZNS?: (address: string) => void;
};

const { width } = Dimensions.get('window');
export const QrCodeInput: React.FC<Prop> = ({
  style,
  value,
  error,
  zns,
  placeholder,
  onChange = () => null,
  onZNS = () => null
}) => {
  const { colors } = useTheme();
  const [qrcodeModal, setQrcodeModal] = React.useState(false);
  const [isLoading, setIsLoading] = React.useState(false);

  const handleQrcode = React.useCallback((qrcode) => {
    const address = String(qrcode).replace('zilliqa://', '');

    onChange(address);
  }, [onChange]);
  const hanldeChange = React.useCallback(async(text) => {
    if (!zns) {
      return onChange(text);
    }

    const regExpDomain = /.*\w.zil/gm;

    if (regExpDomain.test(text)) {
      setIsLoading(true);

      try {
        const res = await keystore.ud.getAddressByDomain(text);
        const bech32 = toBech32Address(res.address || res.owner);

        onZNS(res.domain);
        onChange(bech32);
      } catch (err) {
        //
      }
      setIsLoading(false);

      return null;
    }

    onChange(text);
  }, [onChange, onZNS]);

  return (
    <React.Fragment>
      <View style={[styles.container, style, {
        borderBottomColor: error ? colors['danger'] : colors.border
      }]}>
        {isLoading ? (
          <ActivityIndicator
            animating={isLoading}
            color={colors.primary}
          />
        ) : null}
        <TextInput
          style={[styles.textInput, {
            color: error ? colors['danger'] : colors.text
          }]}
          autoCorrect={false}
          placeholder={placeholder}
          value={value}
          placeholderTextColor={colors.border}
          onSubmitEditing={() => null}
          onChangeText={hanldeChange}
        />
        <TouchableOpacity onPress={() => setQrcodeModal(true)}>
          <SvgXml xml={QrcodeIconSVG}/>
        </TouchableOpacity>
      </View>
      <Text style={[styles.error, {
        color: colors['danger']
      }]}>
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
    fontFamily: fonts.Demi,
    width: width - 100
  },
  error: {
    fontSize: 13,
    fontFamily: fonts.Demi
  }
});
