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
  Dimensions,
  Text,
  Button
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import { RootParamList } from 'app/navigator';

import CreateBackground from 'app/assets/get_started_1.svg';

import i18n from 'app/lib/i18n';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const { width } = Dimensions.get('window');
export const InitSuccessfullyPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const hanldeOK = React.useCallback(() => {
    navigation.navigate('App', { screen: 'Home' });
  }, [navigation]);

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <View style={[StyleSheet.absoluteFill, styles.backgroundImage]}>
        <CreateBackground
          width={width + width / 4}
          height={width + width / 4}
        />
      </View>
      <View style={styles.wrapper}>
        <Text style={[styles.title , {
          color: colors.text
        }]}>
          {i18n.t('successfully_title')}
        </Text>
        <Button
          color={colors.primary}
          title={i18n.t('successfully_btn')}
          onPress={hanldeOK}
        />
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  backgroundImage: {
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: '40%'
  },
  wrapper: {
    height: '90%',
    alignItems: 'center',
    justifyContent: 'flex-end'
  },
  title: {
    fontWeight: 'bold',
    lineHeight: 41,
    fontSize: 34,
    textAlign: 'center',
    marginBottom: 100
  }
});

export default InitSuccessfullyPage;
