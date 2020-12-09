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
  Dimensions,
  StyleSheet
} from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

import { CustomButton } from 'app/components/custom-button';
import { Selector } from 'app/components/selector';
import { AccountName } from 'app/components/account-name';
import { Passwordinput } from 'app/components/password-input';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { theme } from 'app/styles';

type Prop = {
  biometricEnable: boolean;
  onImported: () => void;
};

const { height } = Dimensions.get('window');
const variants = [
  'Private Key',
  'Ledger'
];
export const ImportAccount: React.FC<Prop> = ({
  biometricEnable,
  onImported
}) => {
  const accountState = keystore.account.store.useValue();

  const [loading, setLoading] = React.useState(false);
  const [selected, setSelected] = React.useState(variants[0]);
  const [lastindex, setlastindex] = React.useState(keystore.account.lastIndexLedger);
  const [accName, setAccName] = React.useState(`Imported ${lastindex}`);
  const [ledgerIndex, setLedgerIndex] = React.useState(
    keystore.account.lastIndexLedger
  );
  const [privateKey, setPrivateKey] = React.useState<string | null>(null);
  const [privKeyErr, setPrivKeyErr] = React.useState('');
  const [password, setPassword] = React.useState<string | undefined>();
  const [passwordError, setPasswordError] = React.useState(' ');

  const disabled = React.useMemo(() => {
    if (variants[0] === selected) {
      return !privateKey || !accName;
    } else if (variants[1] === selected) {
      return isNaN(Number(ledgerIndex)) || !accName;
    }
  }, [privateKey, accName, ledgerIndex]);

  const handleimport = React.useCallback(async() => {
    setLoading(true);
    if (variants[0] === selected && privateKey) {
      try {
        await keystore.addPrivateKeyAccount(
          privateKey,
          accName,
          password
        );
        onImported();
      } catch (err) {
        setPrivKeyErr(err.message);
      }
    }

    if (variants[1] === selected) {
      //
    }

    setLoading(false);
  }, [password, privateKey, selected, accName, onImported, setPrivKeyErr]);
  const hanldeLedgerChange = React.useCallback((num) => {
    const index = Number(num);

    if (!isNaN(index)) {
      setLedgerIndex(index);
    }
  }, [setLedgerIndex]);
  const handleChangeType = React.useCallback((value) => {
    setSelected(value);
    setPrivKeyErr('');
  }, [setSelected, setAccName]);
  const hanldeChangePrivKey = React.useCallback((value) => {
    setPrivKeyErr('');
    setPrivateKey(value);
  }, [setPrivateKey, setPrivKeyErr]);

  React.useEffect(() => {
    if (selected === variants[0]) {
      setAccName(i18n.t('acc_name_key', {
        index: keystore.account.lastIndexPrivKey
      }));
    } else if (selected === variants[1]) {
      setAccName(i18n.t('acc_name_ledger', {
        index: keystore.account.lastIndexLedger
      }));
    }
  }, [selected, accountState, setlastindex]);

  return (
    <KeyboardAwareScrollView>
      <Selector
        style={{ backgroundColor: 'transparent' }}
        items={variants}
        selected={selected}
        onSelect={handleChangeType}
      />
      <View style={styles.wrapper}>
        <AccountName
          style={{ paddingVertical: 15}}
          name={accName}
          setName={setAccName}
        />
        {variants[0] === selected ? (
          <View>
            <TextInput
              multiline={true}
              numberOfLines={10}
              style={styles.text}
              placeholder={i18n.t('import_private_key_placeholder')}
              placeholderTextColor="#8A8A8F"
              onChangeText={hanldeChangePrivKey}
            />
            <Text style={styles.errorMessage}>
              {privKeyErr}
            </Text>
            {!biometricEnable ? (
              <Passwordinput
                style={{ marginVertical: 15 }}
                passwordError={passwordError}
                placeholder={i18n.t('pass_setup_input1')}
                onChange={setPassword}
              />
            ) : null}
          </View>
        ) : null}
        {variants[1] === selected ? (
          <TextInput
            value={String(ledgerIndex)}
            keyboardType={'numeric'}
            style={styles.text}
            onChangeText={hanldeLedgerChange}
          />
        ) : null}
        <CustomButton
          style={{ marginTop: 15 }}
          title={i18n.t('import_account')}
          disabled={disabled}
          isLoading={loading}
          onPress={handleimport}
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
  errorMessage: {
    color: theme.colors.danger,
    fontSize: 13,
    marginLeft: 5,
    lineHeight: 22
  },
  text: {
    marginTop: 15,
    height: height / 10,
    borderColor: '#8A8A8F',
    borderWidth: 1,
    borderRadius: 8,
    color: theme.colors.white,
    padding: 20,
    fontSize: 23
  }
});