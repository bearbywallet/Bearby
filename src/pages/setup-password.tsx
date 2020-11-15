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
  Text,
  TextInput,
  Button,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { SvgXml } from 'react-native-svg';

import { ProfileSVG, LockSVG } from 'app/components/svg';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { RouteProp } from '@react-navigation/native';
import { RootStackParamList } from 'app/router';

type Prop = {
  navigation: StackNavigationProp<RootStackParamList, 'SetupPassword'>;
  route: RouteProp<RootStackParamList, 'SetupPassword'>;
};

export const SetupPasswordPage: React.FC<Prop> = ({ navigation, route }) => {
  const [mnemonicPhrase] = React.useState(route.params.phrase);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        {i18n.t('password_title')}
      </Text>
      <View style={styles.wrapper}>
        <View style={styles.elementWrapper}>
          <View style={styles.inputWrapper}>
            <SvgXml xml={ProfileSVG} />
            <TextInput
              style={styles.textInput}
              placeholder={i18n.t('pass_setup_input0')}
              placeholderTextColor="#2B2E33"
            />
          </View>
          <Text style={styles.label}>
            {i18n.t('pass_setup_label0')}
          </Text>
        </View>
        <View style={styles.elementWrapper}>
          <View style={styles.inputWrapper}>
            <SvgXml xml={LockSVG} />
            <TextInput
              style={styles.textInput}
              placeholder={i18n.t('pass_setup_input1')}
              placeholderTextColor="#2B2E33"
            />
          </View>
          <View style={{ marginLeft: 39 }}>
            <TextInput
              style={styles.textInput}
              placeholder={i18n.t('pass_setup_input2')}
              placeholderTextColor="#2B2E33"
            />
          </View>
          <Text style={styles.label}>
            {i18n.t('pass_setup_label1')}
          </Text>
          <Text style={styles.label}>
            {i18n.t('pass_setup_label2')}
          </Text>
        </View>
      </View>
      <Button
        title={i18n.t('pass_setup_btn')}
        color={theme.colors.primary}
        onPress={() => null}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    backgroundColor: theme.colors.black
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    borderBottomColor: '#2B2E33',
    borderBottomWidth: 1,
    width: '90%'
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  elementWrapper: {
    marginVertical: 35
  },
  label: {
    marginVertical: 5,
    color: '#8A8A8F',
    marginLeft: 38
  },
  title: {
    textAlign: 'center',
    fontWeight: 'bold',
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41,
    marginTop: 30
  },
  wrapper: {
    paddingHorizontal: 20,
    marginTop: 40,
    marginBottom: '50%'
  }
});

export default SetupPasswordPage;
