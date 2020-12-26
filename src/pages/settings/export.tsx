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
import SafeAreaView from 'react-native-safe-area-view';
import { RouteProp, useTheme } from '@react-navigation/native';
import Clipboard from '@react-native-community/clipboard';
import { StackNavigationProp } from '@react-navigation/stack';

import { CustomButton } from 'app/components/custom-button';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { SecureTypes } from 'app/config';
import { SettingsStackParamList } from 'app/navigator/settings';

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

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
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
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  wrapper: {
    marginVertical: 20,
    padding: 15
  },
  dangerWrapper: {
    borderLeftWidth: 2,
    padding: 5
  },
  dangerText: {
    fontSize: 16,
    lineHeight: 21
  },
  contentText: {
    marginTop: 30,
    textAlign: 'center',
    fontSize: 17,
    lineHeight: 22
  },
  btn: {
    marginTop: 20
  }
});

export default ExportPage;
