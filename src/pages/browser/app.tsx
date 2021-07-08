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
  ScrollView,
  Dimensions,
  Text,
  ListRenderItemInfo
} from 'react-native';
import URL from 'url-parse';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';
import FastImage from 'react-native-fast-image';
import Carousel from 'react-native-snap-carousel';

import { CustomButton } from 'app/components/custom-button';

import { BrwoserStackParamList } from 'app/navigator/browser';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';
import { keystore } from 'app/keystore';
import { URLTypes } from 'app/lib/controller/search-engine/url-type';

type Prop = {
  navigation: StackNavigationProp<BrwoserStackParamList>;
  route: RouteProp<BrwoserStackParamList, 'BrowserApp'>;
};

const { height, width } = Dimensions.get('window');
export const BrowserAppPage: React.FC<Prop> = ({ route, navigation }) => {
  const { colors } = useTheme();
  const ipfsState = keystore.ipfs.store.useValue();
  const [description, setDescription] = React.useState<string>();

  const ipfsURL = React.useMemo(() =>
    ipfsState.list[ipfsState.selected].url,
    [ipfsState]
  );

  const handleLaunch = React.useCallback(() => {
    navigation.navigate('Web', {
      url: route.params.app.url
    });
  }, [navigation, route]);

  React.useEffect(() => {
    fetch(`${ipfsURL}/${route.params.app.description}`)
      .then((res) => res.json())
      .then((value) => setDescription(value.text))
      .catch(() => setDescription(''));
  }, [ipfsURL]);

  return (
    <View>
      <ScrollView style={[styles.container, {
        backgroundColor: colors.card
      }]}>
        <View style={styles.titleContainer}>
          <FastImage
            source={{ uri: `${ipfsURL}/${route.params.app.icon}` }}
            style={styles.icon}
          />
          <View>
            <Text style={[styles.title, {
              color: colors.text
            }]}>
              {route.params.app.title}
            </Text>
            <Text style={[styles.host, {
              color: colors.border
            }]}>
              {new URL(route.params.app.url).host}
            </Text>
          </View>
        </View>
        <Carousel
          data={route.params.app.images}
          renderItem={(data: ListRenderItemInfo<string>) => (
            <FastImage
              source={{ uri: `${ipfsURL}/${data.item}` }}
              style={[styles.previewImages, {
                backgroundColor: colors['card1']
              }]}
            />
          )}
          sliderWidth={width}
          itemWidth={width - 16}
          sliderHeight={height * 0.50}
          useScrollView={true}
          loop
        />
        {description ? (
          <Text style={[styles.description, {
            color: colors.text
          }]}>
            {description}
          </Text>
        ) : null}
        <CustomButton
          title={i18n.t('launch_app')}
          style={styles.launch}
          onPress={handleLaunch}
        />
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    borderTopRightRadius: 16,
    borderTopLeftRadius: 16,
    height: '100%',
    marginTop: 8
  },
  icon: {
    marginHorizontal: 16,
    height: 50,
    width: 50,
    borderRadius: 100
  },
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 16
  },
  title: {
    fontFamily: fonts.Bold,
    fontSize: 32
  },
  host: {
    fontFamily: fonts.Regular,
    fontSize: 16,
    marginTop: 5
  },
  previewImages: {
    height: height / 3,
    borderRadius: 8
  },
  description: {
    fontFamily: fonts.Regular,
    fontSize: 17,
    padding: 16,
    textAlign: 'center'
  },
  launch: {
    maxWidth: 300,
    minWidth: 200,
    alignSelf: 'center'
  }
});

export default BrowserAppPage;
