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
  Image
} from 'react-native';
import { SafeWrapper } from 'app/components/safe-wrapper';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import { RootParamList } from 'app/navigator';
import { Button } from 'app/components/button';

import CreateBackground from 'app/assets/images/get_started_0.webp';

import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';

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
    <SafeWrapper>
      <View style={[StyleSheet.absoluteFill, styles.backgroundImage]}>
        <Image
          source={CreateBackground}
          style={styles.imageStyles}
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
    </SafeWrapper>
  );
};

const styles = StyleSheet.create({
  backgroundImage: {
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: '40%'
  },
  imageStyles: {
    width,
    height: '90%',
    resizeMode: 'contain'
  },
  wrapper: {
    height: '80%',
    alignItems: 'center',
    justifyContent: 'flex-end'
  },
  title: {
    fontFamily: fonts.Bold,
    fontSize: 24,
    textAlign: 'center',
    marginBottom: 100
  }
});

export default InitSuccessfullyPage;
