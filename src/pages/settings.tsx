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
  Text,
  ScrollView,
  View
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import { ListItem } from 'app/components/list-item';
import {
  GearIconSVG,
  AdvancedIconSVG,
  ProfileSVG,
  NetworkIconSVG,
  BookIconSVG,
  AboutIconSVG,
  SecureIconSVG,
  SearchIconSVG,
  ConnectIconSVG
} from 'app/components/svg';

import i18n from 'app/lib/i18n';
import { RootParamList } from 'app/navigator';
import { fonts } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const SettingsPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();

  const list = [
    {
      value: i18n.t('settings_item_account'),
      icon: ProfileSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'AccountSettings'
      })
    },
    {
      value: i18n.t('settings_item0'),
      icon: BookIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'Contacts'
      })
    },
    {
      value: i18n.t('settings_item1'),
      icon: GearIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'General'
      })
    },
    {
      value: i18n.t('settings_item2'),
      icon: AdvancedIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'Advanced'
      })
    },
    {
      value: i18n.t('settings_item3'),
      icon: NetworkIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'Network'
      })
    },
    {
      value: i18n.t('settings_item7'),
      icon: SearchIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'BrowserSettings'
      })
    },
    {
      value: i18n.t('settings_item4'),
      icon: ConnectIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'Connections'
      })
    },
    {
      value: i18n.t('settings_item5'),
      icon: SecureIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'Security'
      })
    },
    {
      value: i18n.t('settings_item6'),
      icon: AboutIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'About'
      })
    }
  ];

  return (
    <View style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <Text style={[styles.title, {
        color: colors.text
      }]}>
        {i18n.t('settings_title')}
      </Text>
      <ScrollView style={{
        borderTopLeftRadius: 16,
        borderTopRightRadius: 16,
        backgroundColor: colors.card
      }}>
        {list.map((el, index) => (
          <ListItem
            key={index}
            text={el.value}
            icon={el.icon}
            last={list.length === index + 1}
            onPress={el.onLink}
          />
        ))}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    borderTopEndRadius: 16,
    borderTopStartRadius: 16
  },
  title: {
    fontSize: 30,
    fontFamily: fonts.Bold,
    padding: 15,
    marginTop: '10%'
  }
});
