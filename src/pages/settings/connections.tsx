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
  ScrollView,
  StyleSheet
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import { BrowserAppItem } from 'app/components/browser';
import { SimpleConfirm } from 'app/components/modals';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { Connect } from 'types';
import { fonts } from 'app/styles';

export const ConnectionsPage = () => {
  const { colors } = useTheme();
  const connectState = keystore.connect.store.useValue();

  const [rmConnect, setRmConnect] = React.useState<Connect>();

  const handleRemove = React.useCallback(() => {
    if (rmConnect) {
      keystore.connect.rm(rmConnect);
    }

    setRmConnect(undefined);
  }, [rmConnect, setRmConnect]);

  return (
    <React.Fragment>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('connections_title')}
        </Text>
        <Button
          title={i18n.t('connections_remove_all')}
          color={colors.primary}
          onPress={() => keystore.connect.reset()}
        />
      </View>
      <ScrollView style={styles.list}>
        {connectState.length === 0 ? (
          <Text style={[styles.noConnect, {
            color: colors.notification
          }]}>
            {i18n.t('havent_connections')}
          </Text>
        ) : null}
        {connectState.map((item, index) => (
          <BrowserAppItem
            style={{
              borderRadius: 0,
              backgroundColor: colors.card
            }}
            key={index}
            title={item.title}
            domain={item.domain}
            icon={item.icon}
            onPress={() => setRmConnect(item)}
          />
        ))}
      </ScrollView>
      <SimpleConfirm
        title={i18n.t('remove_connect', {
          name: rmConnect?.domain
        })}
        description={i18n.t('remove_seed_acc_des')}
        btns={[i18n.t('reject'), i18n.t('confirm')]}
        visible={Boolean(rmConnect)}
        onConfirmed={handleRemove}
        onTriggered={() => setRmConnect(undefined)}
      />
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 16,
    paddingHorizontal: 15
  },
  title: {
    fontSize: 30,
    fontFamily: fonts.Bold
  },
  list: {
    marginTop: 16,
    marginBottom: 100
  },
  noConnect: {
    fontSize: 17,
    fontFamily: fonts.Regular,
    paddingLeft: 15
  }
});

export default ConnectionsPage;
