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
  View,
  Alert,
  Text,
  RefreshControl
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';

import { BrowserCategoryLoading } from 'app/components/browser/category-loading';
import { BrowserCategoryItem } from 'app/components/browser/category-item';

import { BrwoserStackParamList } from 'app/navigator/browser';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';
import { ScrollView } from 'react-native-gesture-handler';
import { keystore } from 'app/keystore';
import { DApp } from 'types';

type Prop = {
  navigation: StackNavigationProp<BrwoserStackParamList>;
  route: RouteProp<BrwoserStackParamList, 'Category'>;
};

export const BrowserCategoryPage: React.FC<Prop> = ({ route }) => {
  const { colors } = useTheme();
  const [loading, setLoading] = React.useState(true);
  const [list, setList] = React.useState<DApp[]>([]);

  const hanldeRefresh = React.useCallback(async(force) => {
    setLoading(true);

    try {
      const result = await keystore.app.getAppsByCategory(
        route.params.category,
        force
      );

      setList(result);
    } catch (err) {
      Alert.alert(
        i18n.t('update'),
        err.message,
        [
          { text: "OK" }
        ]
      );
    }

    setLoading(false);
  }, [route]);

  React.useEffect(() => {
    hanldeRefresh(false);
  }, []);

  return (
    <View>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t(`category_${route.params.category}`)}
        </Text>
      </View>
      <ScrollView
        style={[styles.container, {
          backgroundColor: colors.card
        }]}
        refreshControl={
          <RefreshControl
            refreshing={loading}
            onRefresh={() => hanldeRefresh(true)}
          />
        }
      >
        {loading ? (
          <BrowserCategoryLoading />
        ) : null}
        {list.map((app, index) => (
          <BrowserCategoryItem
            key={index}
            app={app}
            style={{
              marginTop: index === 0 ? 0 : 8
            }}
            onPress={() => null}
          />
        ))}
        {!loading && list.length === 0 ? (
          <Text style={[styles.placeholder, {
            color: colors.notification
          }]}>
            {i18n.t('havent_apps')}
          </Text>
        ) : null}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 15,
    borderTopRightRadius: 16,
    borderTopLeftRadius: 16,
    height: '100%',
    marginTop: 8,
    padding: 16
  },
  titleWrapper: {
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  title: {
    fontSize: 30,
    fontFamily: fonts.Bold
  },
  placeholder: {
    fontSize: 16,
    fontFamily: fonts.Regular
  }
});

export default BrowserCategoryPage;
