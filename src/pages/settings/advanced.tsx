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
  StyleSheet,
  Text,
  ScrollView
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import { GasSelector } from 'app/components/gas-selector';
import { Button } from 'app/components/button';
import { DropMenu } from 'app/components/drop-menu';

import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';
import { DEFAULT_GAS } from 'app/config';
import { fonts } from 'app/styles';
import { Switcher } from 'app/components/switcher';

export const AdvancedPage: React.FC = () => {
  const { colors } = useTheme();
  const settingsState = keystore.settings.store.useValue();
  const gasState = keystore.gas.store.useValue();
  const ipfsState = keystore.ipfs.store.useValue();
  const [loading, setLoading] = React.useState(false);

  const hanldeReset = React.useCallback(() => {
    keystore.settings.reset();
    keystore.gas.reset();
  }, []);

  const handleUpdateIPFS = React.useCallback(async() => {
    setLoading(true);
    await keystore.ipfs.reset();
    setLoading(false);
  }, []);
  const handleChangeIPFS = React.useCallback(async(el) => {
    const foundIndex = ipfsState.list.findIndex((e) => e.name === el.name);

    if (foundIndex >= 0) {
      await keystore.ipfs.setSelected(foundIndex);
    }
  }, [ipfsState]);

  const halndeOnToggleFormat = React.useCallback(async(value: boolean) => {
    if (value) {
      await keystore.settings.setFormat(keystore.settings.formats[1]);
    } else {
      await keystore.settings.setFormat(keystore.settings.formats[0]);
    }
  }, []);

  const hanldeChangeFormating = React.useCallback(async() => {
    await keystore.settings.toggleNumberFormat();
  }, [settingsState]);

  return (
    <View>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('advanced_title')}
        </Text>
        <Button
          title={i18n.t('reset')}
          color={colors.primary}
          onPress={hanldeReset}
        />
      </View>
      <ScrollView>
        <GasSelector
          style={{ marginVertical: 16 }}
          selectedColor={colors.background}
          gasLimit={gasState.gasLimit}
          gasPrice={gasState.gasPrice}
          defaultGas={DEFAULT_GAS}
          onChange={(gas) => keystore.gas.changeGas(gas)}
        />
        <DropMenu
          selected={{
            name: ipfsState.list[ipfsState.selected].name
          }}
          title={i18n.t('advanced_ipfs_title')}
          list={ipfsState.list}
          isLoading={loading}
          onUpdate={handleUpdateIPFS}
          onSelect={handleChangeIPFS}
        />
        <Switcher
          style={{
            backgroundColor: colors.card,
            padding: 15,
            marginVertical: 16
          }}
          enabled={settingsState.formated}
          onChange={hanldeChangeFormating}
        >
          <View style={styles.switcherWrapper}>
            <Text style={[styles.someText, {
              color: colors.text
            }]}>
              {i18n.t('title_number_format')}
            </Text>
            <Text style={[styles.someLable, {
              color: colors.border
            }]}>
              {i18n.t('warn_number_format')}
            </Text>
          </View>
        </Switcher>
        <Switcher
          style={{
            backgroundColor: colors.card,
            padding: 15,
            marginVertical: 16
          }}
          enabled={settingsState.addressFormat === keystore.settings.formats[1]}
          onChange={halndeOnToggleFormat}
        >
          <View style={styles.switcherWrapper}>
            <Text style={[styles.someText, {
              color: colors.text
            }]}>
              Base16
            </Text>
            <Text style={[styles.someLable, {
              color: colors.border
            }]}>
              {i18n.t('warn_address_format')}
            </Text>
          </View>
        </Switcher>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 16,
    paddingHorizontal: 15
  },
  title: {
    fontSize: 30,
    fontFamily: fonts.Bold
  },
  switcherWrapper: {
    maxWidth: '70%',
    marginVertical: 16
  },
  someLable: {
    fontSize: 16,
    fontFamily: fonts.Regular,
    marginLeft: 10
  },
  someText: {
    fontSize: 17,
    fontFamily: fonts.Bold
  }
});

export default AdvancedPage;
