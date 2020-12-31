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
  Text,
  StyleSheet,
  FlatList,
  View,
  LayoutAnimation
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import { BrowserAppItem } from './app-item';
import { SwipeRow } from 'app/components/swipe-row';

import i18n from 'app/lib/i18n';
import { Connect } from 'types';
import { fonts } from 'app/styles';

type Prop = {
  connections: Connect[];
  onGoConnection: (connct: Connect) => void;
  onRemove: (connect: Connect) => void;
};

export const BrowserFavorites: React.FC<Prop> = ({
  connections,
  onGoConnection,
  onRemove
}) => {
  const { colors } = useTheme();

  const hanldeRemove = React.useCallback((itemIndex: number) => {
    onRemove(connections[itemIndex]);
    // Animate list to close gap when item is deleted
    LayoutAnimation.configureNext(LayoutAnimation.Presets.spring);
  }, [connections]);

  return (
    <View style={styles.container}>
      {connections.length === 0 ? (
        <Text style={[styles.havent, {
          color: colors.notification
        }]}>
          {i18n.t('havent_connections')}
        </Text>
      ) : null}
      <FlatList
        data={connections}
        renderItem={({ item, index}) => (
          <SwipeRow
            index={index}
            swipeThreshold={-150}
            onSwipe={hanldeRemove}
          >
            <BrowserAppItem
              style={{
                marginTop: 10
              }}
              title={item.title}
              icon={item.icon}
              domain={item.domain}
              onPress={() => onGoConnection(item)}
            />
          </SwipeRow>
        )}
        keyExtractor={(item) => item.domain}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  havent: {
    fontSize: 17,
    fontFamily: fonts.Regular,
    paddingTop: 15
  },
});
