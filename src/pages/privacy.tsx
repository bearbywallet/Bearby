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
  ScrollView
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import i18n from 'app/lib/i18n';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import { Button } from 'app/components/button';
import { fonts } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};

const SubTitle: React.FC = ({ children }) => {
  const { colors } = useTheme();

  return (
    <Text style={[styles.sub, {
      color: colors.text
    }]}>
      {children}
    </Text>
  );
};

const Description: React.FC = ({ children }) => {
  const { colors } = useTheme();

  return (
    <Text style={[styles.description, {
      color: colors.text
    }]}>
      {children}
    </Text>
  );
};

export const PrivacyPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <SubTitle>
        {i18n.t('privacy_sub')}
      </SubTitle>
      <ScrollView style={styles.content}>
        <Description>
          {i18n.t('privacy_0')}
        </Description>
        <Description>
          {i18n.t('privacy_1')}
        </Description>
        <Description>
          {i18n.t('privacy_2')}
        </Description>
        <Description>
          {i18n.t('privacy_3')}
        </Description>
        <SubTitle>
          {i18n.t('privacy_4')}
        </SubTitle>
        <Description>
          {i18n.t('privacy_5')}
          {i18n.t('privacy_6')}
        </Description>
        <SubTitle>
          {i18n.t('privacy_7')}
        </SubTitle>
        <Description>
          {i18n.t('privacy_8')}
        </Description>
        <SubTitle>
          {i18n.t('privacy_9')}
        </SubTitle>
        <Description>
          {i18n.t('privacy_10')}
        </Description>
        <Description>
          {i18n.t('privacy_11')}
        </Description>
        <Description>
          {i18n.t('privacy_12')}
        </Description>
        <Description>
          {i18n.t('privacy_13')}
        </Description>
        <SubTitle>
          {i18n.t('privacy_14')}
        </SubTitle>
        <Description>
          {i18n.t('privacy_15')}
        </Description>
        <Description>
          {i18n.t('privacy_16')}
        </Description>
        <SubTitle>
          {i18n.t('privacy_17')}
        </SubTitle>
        <Description>
          {i18n.t('privacy_18')}
          {i18n.t('privacy_19')}
          {i18n.t('privacy_20')}
          {i18n.t('privacy_21')}
          {i18n.t('privacy_22')}
          {i18n.t('privacy_23')}
        </Description>
        <SubTitle>
          {i18n.t('privacy_24')}
        </SubTitle>
        <Description>
          {i18n.t('privacy_25')}
        </Description>
        <SubTitle>
          {i18n.t('privacy_26')}
        </SubTitle>
        <Description>
          {i18n.t('privacy_27')}
        </Description>
        <SubTitle>
          {i18n.t('privacy_28')}
        </SubTitle>
        <Description>
          {i18n.t('privacy_29')}
        </Description>
        <SubTitle>
          {i18n.t('privacy_30')}
        </SubTitle>
        <Description>
          {i18n.t('privacy_31')}
        </Description>
        <SubTitle>
          {i18n.t('privacy_32')}
        </SubTitle>
        <Description>
          {i18n.t('privacy_33')}
        </Description>
      </ScrollView>
      <View style={[styles.bottomView, {
        backgroundColor: colors.card
      }]}>
        <Button
          style={{
            padding: 10
          }}
          title={i18n.t('accept')}
          color={colors.primary}
          onPress={() => navigation.navigate('LetStart')}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center'
  },
  sub: {
    fontFamily: fonts.Bold,
    textAlign: 'center',
    fontSize: 16,
    paddingHorizontal: 30,
    marginVertical: 20
  },
  content: {
    width: '90%'
  },
  description: {
    textAlign: 'left',
    fontFamily: fonts.Regular,
    marginVertical: 5
  },
  bottomView: {
    borderTopLeftRadius: 5,
    borderTopRightRadius: 5,
    width: '100%',
    height: 70
  }
});

export default PrivacyPage;
