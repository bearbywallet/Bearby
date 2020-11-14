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
  Button
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';

import { Chip } from 'app/components/chip';

import { RootStackParamList } from 'app/router';
import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';

type Prop = {
  navigation: StackNavigationProp<RootStackParamList, 'MnemonicVerif'>;
};

export const MnemonicVerifypage: React.FC<Prop> = ({ navigation }) => {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        {i18n.t('verify_title')}
      </Text>
      <View>
        <Chip>
          sadsad
        </Chip>
      </View>
      <View>
        <Text style={styles.subTitle}>
          {i18n.t('verify_sub_title')}
        </Text>
        <Button
          title={i18n.t('verify_btn')}
          color={theme.colors.primary}
          onPress={() => null}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  title: {
    textAlign: 'center',
    lineHeight: 41,
    fontSize: 31,
    fontWeight: 'bold',
    color: theme.colors.white,
    marginTop: 30
  },
  subTitle: {
    textAlign: 'center',
    color: '#8A8A8F',
    lineHeight: 21,
    fontSize: 16,
  }
});

export default MnemonicVerifypage;
