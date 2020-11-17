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
  StyleSheet,
  Text,
  View
} from 'react-native';
import { SvgXml } from 'react-native-svg';

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
import { theme } from 'app/styles';

export const SettingsPage = () => {
  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>
        {i18n.t('settings_title')}
      </Text>
      <View style={styles.list}>
        <View style={styles.listItemWrapper}>
          <SvgXml xml={BookIconSVG} />
          <View style={styles.listItem}>
            <Text style={styles.listTextItem}>
              Contacts
            </Text>
            <SvgXml
              xml={ArrowIconSVG}
              fill={'#666666'}
              style={styles.arrow}
            />
          </View>
        </View>
        <View style={styles.listItemWrapper}>
          <SvgXml xml={GearIconSVG} />
          <View style={styles.listItem}>
            <Text style={styles.listTextItem}>
              General
            </Text>
            <SvgXml
              xml={ArrowIconSVG}
              fill={'#666666'}
              style={styles.arrow}
            />
          </View>
        </View>
        <View style={styles.listItemWrapper}>
          <SvgXml xml={AdvancedIconSVG} />
          <View style={styles.listItem}>
            <Text style={styles.listTextItem}>
              Advanced
            </Text>
            <SvgXml
              xml={ArrowIconSVG}
              fill={'#666666'}
              style={styles.arrow}
            />
          </View>
        </View>
        <View style={styles.listItemWrapper}>
          <SvgXml xml={NetworkIconSVG} />
          <View style={styles.listItem}>
            <Text style={styles.listTextItem}>
              Network
            </Text>
            <SvgXml
              xml={ArrowIconSVG}
              fill={'#666666'}
              style={styles.arrow}
            />
          </View>
        </View>
        <View style={styles.listItemWrapper}>
          <SvgXml xml={ConnectIconSVG} />
          <View style={styles.listItem}>
            <Text style={styles.listTextItem}>
              Connections
            </Text>
            <SvgXml
              xml={ArrowIconSVG}
              fill={'#666666'}
              style={styles.arrow}
            />
          </View>
        </View>
        <View style={styles.listItemWrapper}>
          <SvgXml xml={SecureIconSVG} />
          <View style={styles.listItem}>
            <Text style={styles.listTextItem}>
              Security
            </Text>
            <SvgXml
              xml={ArrowIconSVG}
              fill={'#666666'}
              style={styles.arrow}
            />
          </View>
        </View>
        <View style={styles.listItemWrapper}>
          <SvgXml xml={AboutIconSVG} />
          <View style={styles.listItem}>
            <Text style={styles.listTextItem}>
            About
            </Text>
            <SvgXml
              xml={ArrowIconSVG}
              fill={'#666666'}
              style={styles.arrow}
            />
          </View>
        </View>
      </View>
    </SafeAreaView>
  );
};

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
