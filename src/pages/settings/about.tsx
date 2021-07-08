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
  Image,
  Dimensions
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';

import CreateBackground from 'app/assets/images/get_started_0.webp';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';
import { RootParamList } from 'app/navigator';
import { fonts } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const GIHTUB_URL = 'https://github.com/zilpay/zilpay-mobile';
const PRIVACY_URL = 'https://zilpay.xyz/PrivacyPolicy/';
const TERMS_URL = 'https://zilpay.xyz/Terms/';
const ISSUES = 'https://github.com/zilpay/zilpay-mobile/issues';
export const AboutPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();

  const handleOpen = React.useCallback((url) => {
    navigation.navigate('Browser', {
      screen: 'Web',
      params: {
        url
      }
    });
  }, [navigation]);

  return (
    <View>
      <Text style={[styles.title, {
        color: colors.text
      }]}>
        {i18n.t('about_title')}
      </Text>
      <Image
        source={CreateBackground}
        style={styles.imageStyles}
      />
      <View>
        <Button
          title={i18n.t('about_link_0')}
          color={colors.primary}
          onPress={() => handleOpen(GIHTUB_URL)}
        />
        <Button
          title={i18n.t('about_link_1')}
          color={colors.primary}
          onPress={() => handleOpen(PRIVACY_URL)}
        />
        <Button
          title={i18n.t('about_link_2')}
          color={colors.primary}
          onPress={() => handleOpen(TERMS_URL)}
        />
        <Button
          title={i18n.t('about_link_3')}
          color={colors.primary}
          onPress={() => handleOpen(ISSUES)}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  title: {
    textAlign: 'center',
    fontSize: 30,
    fontFamily: fonts.Bold,
    marginTop: '5%'
  },
  imageStyles: {
    width: 'auto',
    height: '60%',
    resizeMode: 'contain'
  }
});

export default AboutPage;
