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
  Dimensions,
  TextInput,
  StyleSheet,
  ActivityIndicator,
  LayoutAnimation
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';
import { SvgXml } from 'react-native-svg';

import { SearchIconSVG } from 'app/components/svg';
import { TabView, SceneMap } from 'react-native-tab-view';
import { CreateAccountNavBar } from 'app/components/create-account';
import {
  BrowserApps,
  BrowserFavorites
} from 'app/components/browser';

import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';
import { BrwoserStackParamList } from 'app/navigator/browser';

type Prop = {
  navigation: StackNavigationProp<BrwoserStackParamList>;
  route: RouteProp<BrwoserStackParamList, 'Browser'>;
};

enum Tabs {
  apps = 'apps',
  favorites = 'favorites'
}

const { height, width } = Dimensions.get('window');
const initialLayout = { width };
export const BrowserHomePage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const connectState = keystore.connect.store.useValue();

  const [search, setSearch] = React.useState<string>('');
  const [isLoading, setIsLoading] = React.useState(false);

  const [index, setIndex] = React.useState(0);
  const [routes] = React.useState([
    { key: Tabs.apps, title: i18n.t('apps') },
    { key: Tabs.favorites, title: i18n.t('connections_title') }
  ]);

  const hanldeSearch = React.useCallback(async() => {
    setIsLoading(true);
    const url = await keystore.searchEngine.onUrlSubmit(search);
    setIsLoading(false);
    navigation.navigate('Web', {
      url
    });
    LayoutAnimation.configureNext(LayoutAnimation.Presets.spring);
  }, [search]);
  const hanldeSelectCategory = React.useCallback((category) => {
    navigation.navigate('Category', {
      category
    });
  }, [search]);

  const handleConnect = React.useCallback(async(connect) => {
    setIsLoading(true);
    const url = await keystore.searchEngine.onUrlSubmit(connect.domain);
    setIsLoading(false);
    navigation.navigate('Web', {
      url
    });
    LayoutAnimation.configureNext(LayoutAnimation.Presets.spring);
  }, []);

  const renderScene = SceneMap({
    [Tabs.apps]: () => (
      <BrowserApps onSelect={hanldeSelectCategory} />
    ),
    [Tabs.favorites]: () => (
      <BrowserFavorites
        connections={connectState}
        onGoConnection={handleConnect}
        onRemove={(connect) => keystore.connect.rm(connect)}
      />
    )
  });

  return (
    <React.Fragment>
      <SafeAreaView style={[styles.container, {
        backgroundColor: colors.background
      }]}>
        <View style={styles.header}>
          <View style={styles.headerWraper}>
            <Text style={[styles.headerTitle, {
              color: colors.text
            }]}>
              {i18n.t('browser_title')}
            </Text>
          </View>
        </View>
        <View style={[styles.main, {
          backgroundColor: colors.background
        }]}>
          <View style={styles.inputWrapper}>
            {isLoading ? (
              <ActivityIndicator
                animating={isLoading}
                color={colors.primary}
              />
            ) : (
              <SvgXml xml={SearchIconSVG} />
            )}
            <TextInput
              style={[styles.textInput, {
                color: colors.text,
                borderBottomColor: colors.border
              }]}
              autoCorrect={false}
              autoFocus={true}
              autoCapitalize={'none'}
              textContentType={'URL'}
              value={search}
              placeholder={i18n.t('browser_placeholder_input')}
              placeholderTextColor={colors.border}
              onChangeText={setSearch}
              onSubmitEditing={hanldeSearch}
            />
          </View>
          <TabView
            style={styles.tabView}
            renderTabBar={(props) => <CreateAccountNavBar {...props}/>}
            navigationState={{ index, routes }}
            renderScene={renderScene}
            onIndexChange={setIndex}
            initialLayout={initialLayout}
          />
        </View>
      </SafeAreaView>
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  header: {
    alignItems: 'center',
    padding: 15,
    paddingBottom: 30
  },
  headerTitle: {
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold',
    textAlign: 'left'
  },
  headerWraper: {
    width: '100%'
  },
  main: {
    height: height - 100,
    borderTopEndRadius: 16,
    borderTopStartRadius: 16,
    padding: 15
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    borderBottomWidth: 1,
    width: width - 60
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  tabView: {
    marginTop: 15
  }
});

export default BrowserHomePage;
