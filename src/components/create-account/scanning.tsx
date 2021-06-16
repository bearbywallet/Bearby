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
  StyleSheet,
  View,
  ActivityIndicator,
  TouchableOpacity,
  Text,
  PermissionsAndroid
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import TransportBLE from '@ledgerhq/react-native-hw-transport-ble';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import Geolocation from '@react-native-community/geolocation';
import LocationServicesDialogBox from 'react-native-android-location-services-dialog-box';

import { CustomButton } from 'app/components/custom-button';
import { ErrorMessage } from './error-message';
import { LedgerAddModal } from 'app/components/modals';

import i18n from 'app/lib/i18n';
import { Device } from 'app/utils';
import { BleState, LedgerTransport } from 'types';
import { fonts } from 'app/styles';
import LedgerIcon from 'app/assets/icons/ledger.svg';

interface LedgerItem {
  mac: string;
  name: string;
  type: string;
}
export const ScanningDevice: React.FC = () => {
  const { colors } = useTheme();
  const [ble, setBle] = React.useState<boolean | null>(null);
  const [geo, setGeo] = React.useState<boolean | null>(null);
  const [items, setItems] = React.useState<LedgerItem[]>([]);
  const [selected, setSelected] = React.useState<LedgerItem | undefined>();

  const PermissionsAndroidRequest = React.useCallback(async() => {
    const granted = await PermissionsAndroid.check(
      PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
    );

    if (granted) {
      setGeo(granted);

      return null;
    }

    Geolocation.getCurrentPosition(
      async (info) => {
        if (info) {
          const requested = await PermissionsAndroid.request(
              PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
          );
          setGeo(requested === PermissionsAndroid.RESULTS.GRANTED);
        }
      },
      () => null,
      {
        enableHighAccuracy: false,
        timeout: 20000,
        maximumAge: 1000
      }
    );
  }, []);
  const hanldeOpenLocationServicesSetting = React.useCallback(async() => {
    try {
      const status = await LocationServicesDialogBox.checkLocationServicesIsEnabled({
        enableHighAccuracy: false,
        showDialog: false,
        openLocationServices: true
      });

      setGeo(status.enabled);
    } catch (err) {
      // Nothing to do: location is still disabled
    }
  }, []);
  const hanldeAddDevice = React.useCallback((el: LedgerItem) => {
    if (items.some((e) => e.mac === el.mac)) {
      return null;
    }

    setItems([...items, el]);
  }, [items]);

  React.useEffect(() => {
    const subscription = TransportBLE.observeState({
      next: async(e: BleState) => {
        setBle(e.available);

        if (e.available && Device.isAndroid()) {
          await PermissionsAndroidRequest();
        }
      },
      complete: () => null,
      error: () => null
    });
    const listen =  TransportBLE.listen({
      complete: () => null,
      next: async (event: LedgerTransport) => {
        const { descriptor, type } = event;

        listen.unsubscribe();
        hanldeAddDevice({
          type,
          mac: descriptor.id,
          name: descriptor.name
        });
      },
      error: () => null
    });

    return () => {
      subscription.unsubscribe();
      listen.unsubscribe();
    };
  }, []);

  return (
    <KeyboardAwareScrollView style={styles.container}>
      {ble === false ? (
        <ErrorMessage
          title={i18n.t('ble_disabled_title')}
          message={i18n.t('ble_disabled_message')}
        />
      ) : null}
      {geo === false && ble ? (
        <React.Fragment>
          <ErrorMessage
            title={i18n.t('geo_disabled_title')}
            message={i18n.t('geo_disabled_message')}
          />
          <CustomButton
            title={i18n.t('open_location_settings')}
            style={styles.button}
            onPress={hanldeOpenLocationServicesSetting}
          />
        </React.Fragment>
      ) : null}
      {geo && ble ? (
        <View>
          <Text style={[styles.title, {
            color: colors.text
          }]}>
            {i18n.t('scanning_title')}
          </Text>
          <Text
            style={[styles.message, {
              color: colors.notification
            }]}
          >
            {i18n.t('scanning_message')}
          </Text>
        </View>
      ) : null}
      {items.length === 0 ? (
        <ActivityIndicator
          animating={items.length === 0}
          color={colors.primary}
        />
      ) : null}
      {items.map((item, index) => (
        <TouchableOpacity
          style={[styles.itemWrapper, {
            borderColor: colors.border
          }]}
          key={index}
          onPress={() => setSelected(item)}
        >
          <LedgerIcon />
          <Text style={[styles.itemTitle, {
            color: colors.text
          }]}>
            {item.name}
          </Text>
        </TouchableOpacity>
      ))}
      <LedgerAddModal
        title={i18n.t('ledger_connect')}
        mac={selected?.mac || ''}
        visible={Boolean(selected)}
        btnTitle={i18n.t('connect')}
        onTriggered={() => setSelected(undefined)}
        onConfirmed={() => setSelected(undefined)}
      />
    </KeyboardAwareScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingVertical: 16
  },
  button: {
    margin: 16
  },
  title: {
    fontFamily: fonts.Bold,
    fontSize: 20,
    textAlign: 'center'
  },
  message: {
    fontFamily: fonts.Regular,
    fontSize: 16,
    textAlign: 'center'
  },
  itemWrapper: {
    borderRadius: 5,
    borderWidth: 1,
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 16,
    marginHorizontal: 30,
    paddingHorizontal: 16
  },
  itemTitle: {
    fontFamily: fonts.Demi,
    fontSize: 16,
    marginLeft: 36
  }
});
