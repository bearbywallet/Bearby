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
  ScrollView,
  Button
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { RootStackParamList } from 'app/router';

type Prop = {
  navigation: StackNavigationProp<RootStackParamList, 'Privacy'>;
};

export const PrivacyPage: React.FC<Prop> = ({ navigation }) => {
  return (
    <View style={styles.container}>
      <Text style={styles.sub}>
        {i18n.t('privacy_sub')}
      </Text>
      <ScrollView style={styles.content}>
        <Text style={styles.description}>
          {i18n.t('privacy_0')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_1')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_2')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_3')}
        </Text>
        <Text style={styles.sub}>
          {i18n.t('privacy_4')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_5')}
          {i18n.t('privacy_6')}
        </Text>
        <Text style={styles.sub}>
          {i18n.t('privacy_7')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_8')}
        </Text>
        <Text style={styles.sub}>
          {i18n.t('privacy_9')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_10')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_11')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_12')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_13')}
        </Text>
        <Text style={styles.sub}>
          {i18n.t('privacy_14')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_15')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_16')}
        </Text>
        <Text style={styles.sub}>
          {i18n.t('privacy_17')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_18')}
          {i18n.t('privacy_19')}
          {i18n.t('privacy_20')}
          {i18n.t('privacy_21')}
          {i18n.t('privacy_22')}
          {i18n.t('privacy_23')}
        </Text>
        <Text style={styles.sub}>
          {i18n.t('privacy_24')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_25')}
        </Text>
        <Text style={styles.sub}>
          {i18n.t('privacy_26')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_27')}
        </Text>
        <Text style={styles.sub}>
          {i18n.t('privacy_28')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_29')}
        </Text>
        <Text style={styles.sub}>
          {i18n.t('privacy_30')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_31')}
        </Text>
        <Text style={styles.sub}>
          {i18n.t('privacy_32')}
        </Text>
        <Text style={styles.description}>
          {i18n.t('privacy_33')}
        </Text>
      </ScrollView>
      <View style={styles.bottomView}>
        <Button
          title={i18n.t('accept')}
          color={theme.colors.primary}
          onPress={() => navigation.push('Create')}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black,
    alignItems: 'center'
  },
  sub: {
    color: theme.colors.white,
    fontWeight: 'bold',
    textAlign: 'center',
    fontSize: 16,
    paddingHorizontal: 30,
    marginVertical: 20
  },
  content: {
    width: '90%'
  },
  description: {
    color: theme.colors.white,
    textAlign: 'left',
    marginVertical: 5
  },
  bottomView: {
    borderTopLeftRadius: 5,
    borderTopRightRadius: 5,
    backgroundColor: theme.colors.gray,
    width: '100%',
    height: 70
  }
});

export default PrivacyPage;
