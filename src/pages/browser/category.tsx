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
  Text
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';

import { BrowserCategoryLoading } from 'app/components/browser/category-loading';
import { BrowserCategoryItem } from 'app/components/browser/category-item';

import { BrwoserStackParamList } from 'app/navigator/browser';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<BrwoserStackParamList>;
  route: RouteProp<BrwoserStackParamList, 'Category'>;
};

export const BrowserCategoryPage: React.FC<Prop> = ({ route }) => {
  const { colors } = useTheme();
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    setTimeout(() => {
      setLoading(false);
    }, 3000);
  }, []);

  return (
    <View>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t(route.params.category)}
        </Text>
      </View>
      <View style={[styles.container, {
        backgroundColor: colors.card
      }]}>
        {loading ? (
          <BrowserCategoryLoading />
        ) : null}
        <BrowserCategoryItem
          title={'Game of dragons'}
          domain={'dragonzil.xyz'}
          url={'https://res.cloudinary.com/dragonseth/image/upload/1_398.png'}
          onPress={() => null}
        />
        {/* <Text style={[styles.placeholder, {
          color: colors.notification
        }]}>
          {i18n.t('havent_apps')}
        </Text> */}
      </View>
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
