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
  PermissionsAndroid,
  FlatList
} from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import Geolocation from '@react-native-community/geolocation';
import LocationServicesDialogBox from 'react-native-android-location-services-dialog-box';

import { CustomButton } from 'app/components/custom-button';
import { Passwordinput } from 'app/components/password-input';
import { CustomTextInput } from 'app/components/custom-text-input';
import { ErrorMessage } from './error-message';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { Device } from 'app/utils';
import { LedgerController } from 'app/lib/controller/connect/ledger';
import { BleState } from 'types';

type Prop = {
};
const ledger = new LedgerController();
export const ScanningDevice: React.FC<Prop> = () => {
  const [ble, setBle] = React.useState<boolean | null>(null);
  const [geo, setGeo] = React.useState<boolean | null>(null);

  const PermissionsAndroidRequest = React.useCallback(async() => {
    const granted = await PermissionsAndroid.check(
      PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
    );
    Geolocation.getCurrentPosition(
      async info => {
          if (info) {
              if (granted) {
                setGeo(granted);
              } else {
                  const requested = await PermissionsAndroid.request(
                      PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
                  );
                  setGeo(requested === PermissionsAndroid.RESULTS.GRANTED);
              }
          } else {
            setGeo(false);
          }
      },
      (error) => setGeo(false),
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

  React.useEffect(() => {
    const subscription = ledger.transport.observeState({
      next: (e: BleState) => {
        setBle(e.available);

        if (e.available && Device.isAndroid()) {
          PermissionsAndroidRequest();
        }
      },
      complete: () => null,
      error: () => null
    });

    return () => {
      subscription.unsubscribe();
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
    </KeyboardAwareScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingVertical: 16
  },
  button: {
    margin: 16
  }
});
