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
  Text
} from 'react-native';
import { RouteProp, useTheme } from '@react-navigation/native';
import Clipboard from '@react-native-community/clipboard';
import { StackNavigationProp } from '@react-navigation/stack';

import { CustomButton } from 'app/components/custom-button';

import i18n from 'app/lib/i18n';
import { SecureTypes } from 'app/config';
import { SettingsStackParamList } from 'app/navigator/settings';
import { fonts } from 'app/styles';
import { keystore } from 'app/keystore';

type Prop = {
  navigation: StackNavigationProp<SettingsStackParamList>;
  route: RouteProp<SettingsStackParamList, 'Export'>;
};

export const ExportPage: React.FC<Prop> = ({ route, navigation }) => {
  const { colors } = useTheme();
  const dangerMessage = React.useMemo(() => {
    if (route.params.type === SecureTypes.privateKey) {
      return i18n.t('export_private_key_danger');
    } else if (route.params.type === SecureTypes.seed) {
      return i18n.t('export_seed_danger');
    }
  }, [route]);

  const hanldeCopy = React.useCallback(() => {
    Clipboard.setString(route.params.content);
  }, [route]);

  React.useEffect(() => {
    if (route.params.type === SecureTypes.privateKey) {
      navigation.setOptions({
        headerTitle: i18n.t('export_private_key')
      });
    } else if (route.params.type === SecureTypes.seed) {
      navigation.setOptions({
        headerTitle: i18n.t('export_seed')
      });
    } else {
      navigation.goBack();
    }
  }, [navigation, route]);

  React.useEffect(() => {
    keystore.guard.screenForbid();

    return () => keystore.guard.screenAllow();
  }, [route]);

  return (
    <View>
      <View style={[styles.wrapper, {
        backgroundColor: colors.card
      }]}>
        <View style={[styles.dangerWrapper, {
          borderColor: colors['danger']
        }]}>
          <Text style={[styles.dangerText, {
            color: colors['danger']
          }]}>
            {dangerMessage}
          </Text>
        </View>
        <Text style={[styles.contentText, {
          color: colors.text
        }]}>
          {route.params.content}
        </Text>
        <CustomButton
          title={i18n.t('copy')}
          style={{
            ...styles.btn,
            backgroundColor: colors['danger']
          }}
          color={colors.text}
          onPress={hanldeCopy}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  wrapper: {
    padding: 15
  },
  dangerWrapper: {
    borderLeftWidth: 2,
    padding: 5
  },
  dangerText: {
    fontSize: 16,
    fontFamily: fonts.Demi
  },
  contentText: {
    marginTop: 30,
    textAlign: 'center',
    fontFamily: fonts.Regular,
    fontSize: 17
  },
  btn: {
    marginTop: 20
  }
});

export default ExportPage;
