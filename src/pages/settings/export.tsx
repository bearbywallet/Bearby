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
import { RouteProp } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { SecureTypes } from 'app/config';
import { SettingsStackParamList } from 'app/navigator/settings';

type Prop = {
  navigation: StackNavigationProp<SettingsStackParamList>;
  route: RouteProp<SettingsStackParamList, 'Export'>;
};

export const ExportPage: React.FC<Prop> = ({ route, navigation }) => {
  const dangerMessage = React.useMemo(() => {
    if (route.params.type === SecureTypes.privateKey) {
      return i18n.t('export_private_key_danger');
    } else if (route.params.type === SecureTypes.seed) {
      return i18n.t('export_seed_danger');
    }
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
    <SafeAreaView style={styles.container}>
      <View style={styles.wrapper}>
        <View style={styles.dangerWrapper}>
          <Text style={styles.dangerText}>
            {dangerMessage}
          </Text>
        </View>
        <Text style={styles.contentText}>
          {route.params.content}
        </Text>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  wrapper: {
    marginVertical: 20,
    padding: 15,
    backgroundColor: theme.colors.gray
  },
  dangerWrapper: {
    borderLeftWidth: 2,
    borderColor: theme.colors.danger,
    padding: 5
  },
  dangerText: {
    color: theme.colors.danger,
    fontSize: 16,
    lineHeight: 21
  },
  contentText: {
    marginTop: 30,
    textAlign: 'center',
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  }
});

export default ExportPage;
