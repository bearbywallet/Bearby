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
  SafeAreaView,
  Button,
  StyleSheet,
  Dimensions,
  Text,
  View
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';

import CreateBackground from 'app/assets/get_started_1.svg';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};

const { width } = Dimensions.get('window');
export const LetStartPage: React.FC<Prop> = ({ navigation }) => {
  return (
    <SafeAreaView style={styles.container}>
      <View style={[StyleSheet.absoluteFill, styles.backgroundImage]}>
        <CreateBackground
          width={width + width / 2}
          height={width + width / 2}
        />
      </View>
      <View style={styles.pageContainer}>
        <Text style={styles.title}>
          {i18n.t('get_started')}
        </Text>
        <Text style={styles.subTitle}>
          {i18n.t('create_sub')}
        </Text>
        <View style={styles.buttons}>
          <Button
            title={i18n.t('create')}
            color={theme.colors.primary}
            onPress={() => navigation.navigate('Mnemonic')}
          />
          <Button
            title={i18n.t('restore')}
            color={theme.colors.primary}
            onPress={() => navigation.navigate('Restore')}
          />
        </View>
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  backgroundImage: {
    justifyContent: 'center',
    alignItems: 'center'
  },
  pageContainer: {
    justifyContent: 'flex-end',
    alignItems: 'center',
    height: '100%',
    paddingBottom: 100
  },
  title: {
    fontWeight: 'bold',
    color: theme.colors.white,
    lineHeight: 41,
    fontSize: 34
  },
  subTitle: {
    color: theme.colors.white,
    lineHeight: 22,
    fontSize: 17
  },
  buttons: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    marginTop: 72,
    minWidth: '100%'
  }
});

export default LetStartPage;
