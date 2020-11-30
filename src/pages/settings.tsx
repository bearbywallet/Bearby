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
  TouchableOpacity,
  View
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { StackNavigationProp } from '@react-navigation/stack';

import {
  ArrowIconSVG,
  GearIconSVG,
  AdvancedIconSVG,
  NetworkIconSVG,
  BookIconSVG,
  AboutIconSVG,
  SecureIconSVG,
  ConnectIconSVG
} from 'app/components/svg';

import i18n from 'app/lib/i18n';
import { RootParamList } from 'app/navigator';
import { theme } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const SettingsPage: React.FC<Prop> = ({ navigation }) => (
  <View style={styles.container}>
    <Text style={styles.title}>
      {i18n.t('settings_title')}
    </Text>
    <ScrollView style={styles.list}>
      <TouchableOpacity
        style={styles.listItemWrapper}
        onPress={() => navigation.navigate('SettingsPages', { screen: 'Contacts' })}
      >
        <SvgXml xml={BookIconSVG} />
        <View style={styles.listItem}>
          <Text style={styles.listTextItem}>
            {i18n.t('settings_item0')}
          </Text>
          <SvgXml
            xml={ArrowIconSVG}
            fill={'#666666'}
            style={styles.arrow}
          />
        </View>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.listItemWrapper}
        onPress={() => navigation.navigate('SettingsPages', { screen: 'General' })}
      >
        <SvgXml xml={GearIconSVG} />
        <View style={styles.listItem}>
          <Text style={styles.listTextItem}>
            {i18n.t('settings_item1')}
          </Text>
          <SvgXml
            xml={ArrowIconSVG}
            fill={'#666666'}
            style={styles.arrow}
          />
        </View>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.listItemWrapper}
        onPress={() => navigation.navigate('SettingsPages', { screen: 'Advanced' })}
      >
        <SvgXml xml={AdvancedIconSVG} />
        <View style={styles.listItem}>
          <Text style={styles.listTextItem}>
            {i18n.t('settings_item2')}
          </Text>
          <SvgXml
            xml={ArrowIconSVG}
            fill={'#666666'}
            style={styles.arrow}
          />
        </View>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.listItemWrapper}
        onPress={() => navigation.navigate('SettingsPages', { screen: 'Network' })}
      >
        <SvgXml xml={NetworkIconSVG} />
        <View style={styles.listItem}>
          <Text style={styles.listTextItem}>
            {i18n.t('settings_item3')}
          </Text>
          <SvgXml
            xml={ArrowIconSVG}
            fill={'#666666'}
            style={styles.arrow}
          />
        </View>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.listItemWrapper}
        onPress={() => navigation.navigate('SettingsPages', { screen: 'Connections' })}
      >
        <SvgXml xml={ConnectIconSVG} />
        <View style={styles.listItem}>
          <Text style={styles.listTextItem}>
            {i18n.t('settings_item4')}
          </Text>
          <SvgXml
            xml={ArrowIconSVG}
            fill={'#666666'}
            style={styles.arrow}
          />
        </View>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.listItemWrapper}
        onPress={() => navigation.navigate('SettingsPages', { screen: 'Security' })}
      >
        <SvgXml xml={SecureIconSVG} />
        <View style={styles.listItem}>
          <Text style={styles.listTextItem}>
            {i18n.t('settings_item5')}
          </Text>
          <SvgXml
            xml={ArrowIconSVG}
            fill={'#666666'}
            style={styles.arrow}
          />
        </View>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.listItemWrapper}
        onPress={() => navigation.navigate('SettingsPages', { screen: 'About' })}
      >
        <SvgXml xml={AboutIconSVG} />
        <View style={[styles.listItem, { borderBottomWidth: 0 }]}>
          <Text style={styles.listTextItem}>
            {i18n.t('settings_item6')}
          </Text>
          <SvgXml
            xml={ArrowIconSVG}
            fill={'#666666'}
            style={styles.arrow}
          />
        </View>
      </TouchableOpacity>
    </ScrollView>
  </View>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    backgroundColor: theme.colors.black
  },
  title: {
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold',
    padding: 15,
    marginTop: '10%'
  },
  list: {
    backgroundColor: theme.colors.background
  },
  listItemWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingLeft: 20
  },
  listItem: {
    width: '90%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderBottomColor: '#09090C',
    borderBottomWidth: 1,
    paddingVertical: 15
  },
  listTextItem: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  },
  arrow: {
    transform: [{ rotate: '-90deg'}],
    marginRight: 15
  }
});
