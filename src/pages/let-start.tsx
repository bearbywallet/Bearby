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
  Dimensions,
  Text,
  View
} from 'react-native';
import { SafeWrapper } from 'app/components/safe-wrapper';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import i18n from 'app/lib/i18n';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import { Button } from 'app/components/button';

import CreateBackground from 'app/assets/get_started_1.svg';
import { fonts } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};

const { width } = Dimensions.get('window');
export const LetStartPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();

  return (
    <SafeWrapper>
      <View style={[StyleSheet.absoluteFill, styles.backgroundImage]}>
        <CreateBackground
          width={width + width / 6}
          height={width + width / 6}
        />
      </View>
      <View style={styles.pageContainer}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('get_started')}
        </Text>
        <Text style={[styles.subTitle, {
          color: colors.text
        }]}>
          {i18n.t('create_sub')}
        </Text>
        <View style={styles.buttons}>
          <Button
            title={i18n.t('create')}
            color={colors.primary}
            onPress={() => navigation.navigate('Mnemonic')}
          />
          <Button
            title={i18n.t('restore')}
            color={colors.primary}
            onPress={() => navigation.navigate('Restore')}
          />
          <Button
            title={i18n.t('connect')}
            color={colors.primary}
            onPress={() => navigation.navigate('WalletConnect')}
          />
        </View>
      </View>
    </SafeWrapper>
  );
};

const styles = StyleSheet.create({
  backgroundImage: {
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 300
  },
  pageContainer: {
    justifyContent: 'flex-end',
    alignItems: 'center',
    height: '100%',
    paddingBottom: 100
  },
  title: {
    fontFamily: fonts.Bold,
    lineHeight: 41,
    fontSize: 34
  },
  subTitle: {
    lineHeight: 22,
    fontFamily: fonts.Demi,
    fontSize: 17
  },
  buttons: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    flexWrap: 'wrap',
    marginTop: 72,
    minWidth: '100%'
  }
});

export default LetStartPage;
