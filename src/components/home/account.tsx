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
  Button
} from 'react-native';
import { LogoSVG } from '../svg';
import { SvgXml } from 'react-native-svg';
import { theme } from 'app/styles';
import I18n from 'app/lib/i18n';

export const HomeAccount = () => {
  return (
    <View style={styles.container}>
      <SvgXml
        xml={LogoSVG}
        viewBox="50 0 300 200"
      />
      <View style={[StyleSheet.absoluteFill, styles.content]}>
        <View>
          <Text style={styles.accountName}>
            0
          </Text>
        </View>
        <Text style={styles.accountName}>
          0
        </Text>
        <View style={styles.buttons}>
          <Button
            color={theme.colors.primary}
            title={I18n.t('send')}
            onPress={() => null}
          />
          <View style={styles.seporate}/>
          <Button
            color={theme.colors.primary}
            title={I18n.t('receive')}
            onPress={() => null}
          />
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    height: '30%',
    alignItems: 'center',
    justifyContent: 'center'
  },
  content: {
    alignItems: 'center',
    justifyContent: 'space-around',
    marginTop: 40
  },
  accountName: {
    color: theme.colors.white
  },
  amount: {
    color: theme.colors.white
  },
  buttons: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    alignItems: 'center',
    width: 150,
    marginLeft: 20
  },
  seporate: {
    width: 1,
    height: 40,
    backgroundColor: '#666666'
  }
});
