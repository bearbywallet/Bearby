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
  Button,
  TextInput,
  Dimensions,
  Text,
  StyleSheet
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

import { ProfileSVG, LockSVG } from 'app/components/svg';
import { CustomButton } from 'app/components/custom-button';
import { Selector } from 'app/components/selector';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { theme } from 'app/styles';

const { height } = Dimensions.get('window');
const variants = [
  'Private Key',
  'Ledger'
];
export const ImportAccount: React.FC = ({
}) => {
  const [selected, setSelected] = React.useState(variants[0]);
  const [ledgerIndex, setLedgerIndex] = React.useState(0);

  const hanldeChange = React.useCallback(() => {
    //
  }, []);
  const hanldeLedgerChange = React.useCallback((num) => {
    const index = Number(num);

    if (!isNaN(index)) {
      setLedgerIndex(index);
    }
  }, [setLedgerIndex]);

  return (
    <KeyboardAwareScrollView>
      <Selector
        style={{ backgroundColor: 'transparent' }}
        items={variants}
        selected={selected}
        onSelect={setSelected}
      />
      <View style={styles.wrapper}>
        {variants[0] === selected ? (
          <TextInput
            multiline={true}
            numberOfLines={10}
            style={styles.text}
            placeholder={i18n.t('import_private_key_placeholder')}
            placeholderTextColor="#8A8A8F"
            onChangeText={hanldeChange}
          />
        ) : null}
        {variants[1] === selected ? (
          <TextInput
            defaultValue={String(ledgerIndex)}
            keyboardType={'numeric'}
            style={styles.text}
            onChangeText={hanldeLedgerChange}
          />
        ) : null}
        <CustomButton
          title={i18n.t('import_account')}
        />
      </View>
    </KeyboardAwareScrollView>
  );
};

const styles = StyleSheet.create({
  wrapper: {
    paddingHorizontal: 15,
    justifyContent: 'space-around'
  },
  text: {
    marginTop: 60,
    height: height / 10,
    borderColor: '#8A8A8F',
    borderWidth: 1,
    borderRadius: 8,
    color: theme.colors.white,
    padding: 20,
    fontSize: 23,
    marginBottom: 30
  }
});