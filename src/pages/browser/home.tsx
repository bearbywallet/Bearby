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
  LayoutAnimation,
  TouchableOpacity,
  ListRenderItemInfo
} from 'react-native';
import { SafeWrapper } from 'app/components/safe-wrapper';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';
import Carousel from 'react-native-snap-carousel';

import SearchIconSVG from 'app/assets/icons/search.svg';

import { TabView, SceneMap, SceneRendererProps } from 'react-native-tab-view';
import { CreateAccountNavBar } from 'app/components/create-account';
import {
  BrowserApps,
  BrowserFavorites
} from 'app/components/browser';

import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';
import { BrwoserStackParamList } from 'app/navigator/browser';
import { fonts } from 'app/styles';
import FastImage from 'react-native-fast-image';
import { Poster } from 'types';

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
  const browserState = keystore.app.store.useValue();
  const ipfsState = keystore.ipfs.store.useValue();

  const [search, setSearch] = React.useState<string>('');
  const [isLoading, setIsLoading] = React.useState(false);

  const [index, setIndex] = React.useState(0);
  const [routes] = React.useState([
    { key: Tabs.apps, title: i18n.t('apps') },
    { key: Tabs.favorites, title: i18n.t('connections_title') }
  ]);

  const ipfsURL = React.useMemo(() =>
    ipfsState.list[ipfsState.selected].url,
    [ipfsState]
  );

  const hanldeBanner = React.useCallback(async(bannerURL: string) => {
    setIsLoading(true);
    const url = await keystore.searchEngine.onUrlSubmit(bannerURL);
    setIsLoading(false);
    navigation.navigate('Web', {
      url
    });
  }, [navigation]);
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
    <SafeWrapper>
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
        backgroundColor: colors.card
      }]}>
        <View style={styles.inputWrapper}>
          {isLoading ? (
            <ActivityIndicator
              animating={isLoading}
              color={colors.primary}
            />
          ) : (
            <SearchIconSVG />
          )}
          <TextInput
            style={[styles.textInput, {
              color: colors.text,
              borderBottomColor: colors.border
            }]}
            autoCorrect={false}
            autoCapitalize={'none'}
            textContentType={'URL'}
            value={search}
            placeholder={i18n.t('browser_placeholder_input')}
            placeholderTextColor={colors.border}
            onChangeText={setSearch}
            onSubmitEditing={hanldeSearch}
          />
        </View>
        <View style={{
          height: height * 0.20
        }}>
          <Carousel
            data={browserState}
            renderItem={(data: ListRenderItemInfo<Poster>) => (
              <TouchableOpacity onPress={() => hanldeBanner(data.item.url)}>
                <FastImage
                  source={{ uri: `${ipfsURL}/${data.item.banner}` }}
                  style={[styles.previewImages, {
                    backgroundColor: colors['card1']
                  }]}
                />
              </TouchableOpacity>
            )}
            sliderWidth={sliderWidth}
            itemWidth={slideWidth}
            sliderHeight={slideHeight}
            useScrollView={true}
            loop
          />
        </View>
        <TabView
          renderTabBar={(props: SceneRendererProps) => <CreateAccountNavBar {...props}/>}
          navigationState={{ index, routes }}
          renderScene={renderScene}
          onIndexChange={setIndex}
          initialLayout={initialLayout}
        />
      </View>
    </SafeWrapper>
  );
};

function wp (percentage: number) {
  const value = (percentage * width) / 100;
  return Math.round(value);
}

const slideHeight = height * 0.36;
const slideWidth = wp(75);
const sliderWidth = width;

const styles = StyleSheet.create({
  header: {
    alignItems: 'center',
    padding: 15
  },
  headerTitle: {
    fontSize: 30,
    fontFamily: fonts.Bold,
    textAlign: 'left'
  },
  headerWraper: {
    width: '100%'
  },
  main: {
    height: height + 100,
    borderTopEndRadius: 16,
    borderTopStartRadius: 16,
    padding: 15,
    justifyContent: 'flex-start'
  },
  textInput: {
    fontSize: 17,
    padding: 5,
    fontFamily: fonts.Demi,
    borderBottomWidth: 1,
    width: width - 60
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  previewImages: {
    marginTop: 16,
    height: height / 6,
    borderRadius: 8,
    marginHorizontal: 5
  }
});

export default BrowserHomePage;
