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
  ScrollView
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import { SafeWrapper } from 'app/components/safe-wrapper';
import { ListItem } from 'app/components/list-item';

import AboutIconSVG from 'app/assets/icons/about-icon.svg';
import GearIconSVG from 'app/assets/icons/gear.svg';
import AdvancedIconSVG from 'app/assets/icons/advanced.svg';
import ProfileSVG from 'app/assets/icons/profile.svg';
import NetworkIconSVG from 'app/assets/icons/network.svg';
import BookIconSVG from 'app/assets/icons/book.svg';
import SecureIconSVG from 'app/assets/icons/secure.svg';
import SearchIconSVG from 'app/assets/icons/search.svg';
import ConnectIconSVG from 'app/assets/icons/connect.svg';

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
      Icon: ProfileSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'AccountSettings'
      })
    },
    {
      value: i18n.t('settings_item0'),
      Icon: BookIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'Contacts'
      })
    },
    {
      value: i18n.t('settings_item1'),
      Icon: GearIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'General'
      })
    },
    {
      value: i18n.t('settings_item2'),
      Icon: AdvancedIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'Advanced'
      })
    },
    {
      value: i18n.t('settings_item3'),
      Icon: NetworkIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'Network'
      })
    },
    {
      value: i18n.t('settings_item7'),
      Icon: SearchIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'BrowserSettings'
      })
    },
    {
      value: i18n.t('settings_item4'),
      Icon: ConnectIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'Connections'
      })
    },
    {
      value: i18n.t('settings_item5'),
      Icon: SecureIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'Security'
      })
    },
    {
      value: i18n.t('settings_item6'),
      Icon: AboutIconSVG,
      onLink: () => navigation.navigate('SettingsPages', {
        screen: 'About'
      })
    }
  ];

  return (
    <SafeWrapper style={[styles.container, {
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
            last={list.length === index + 1}
            onPress={el.onLink}
          >
            <el.Icon />
          </ListItem>
        ))}
      </ScrollView>
    </SafeWrapper>
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
    padding: 15
  }
});
