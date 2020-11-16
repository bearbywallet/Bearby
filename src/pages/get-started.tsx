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
  SafeAreaView,
  Text,
  ScrollView,
  Dimensions,
  Button
} from 'react-native';
import { NavigationScreenProp, NavigationState } from 'react-navigation';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';

import GetStartedFirst from 'app/assets/get_started_1.svg';
import GetStartedSecond from 'app/assets/get_started_2.svg';
import GetStartedThird from 'app/assets/get_started_3.svg';

type Prop = {
  navigation: NavigationScreenProp<NavigationState>;
};

const { width, height } = Dimensions.get('window');
const pages = [
  {
    img: <GetStartedFirst width={width} height={'50%'}/>,
    title: i18n.t('get_started_title_1'),
    description: i18n.t('get_started_description_1')
  },
  {
    img: <GetStartedSecond width={width} height={'50%'} />,
    title: i18n.t('get_started_title_2'),
    description: i18n.t('get_started_description_2')
  },
  {
    img: <GetStartedThird width={width} height={'50%'} />,
    title: i18n.t('get_started_title_3'),
    description: i18n.t('get_started_description_3')
  }
];

export const GetStartedPage: React.FC<Prop> = ({ navigation }) => {
  const [sliderState, setSliderState] = React.useState({ currentPage: 0 });

  const setSliderPage = React.useCallback((event) => {
    const { currentPage } = sliderState;
    const { x } = event.nativeEvent.contentOffset;
    const indexOfNextScreen = Math.floor(x / width);

    if (indexOfNextScreen !== currentPage) {
      setSliderState({
        ...sliderState,
        currentPage: indexOfNextScreen,
      });
    }
  }, [sliderState, setSliderState]);

  const { currentPage: pageIndex } = sliderState;

  return (
    <View style={styles.container}>
      <SafeAreaView style={styles.scrollView}>
        <ScrollView
          style={styles.scrollView}
          horizontal={true}
          scrollEventThrottle={16}
          pagingEnabled={true}
          showsHorizontalScrollIndicator={false}
          onScroll={setSliderPage}
        >
        {pages.map((page, index) => (
          <View
            key={index}
            style={[{ width, height }, styles.slideContainer]}
          >
            {page.img}
            <View style={styles.wrapper}>
              <Text style={styles.header}>
                {page.title}
              </Text>
              <Text style={styles.paragraph}>
                {page.description}
              </Text>
            </View>
          </View>
        ))}
        </ScrollView>
        <View style={styles.paginationWrapper}>
          {Array.from(Array(pages.length).keys()).map((_, index) => (
            <View
              key={index}
              style={[
                styles.paginationDots,
                (pageIndex === index ? null : styles.unDot)
              ]}
            />
          ))}
        </View>
        <Button
          title={i18n.t('get_started')}
          color={theme.colors.primary}
          onPress={() => navigation.navigate('Privacy')}
        />
      </SafeAreaView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black,
    paddingVertical: 30
  },
  safeArea: {
    flex: 2
  },
  scrollView: {
    flex: 1
  },
  slideContainer: {
    alignItems: 'center'
  },
  wrapper: {
    justifyContent: 'center',
    alignItems: 'center',
    marginVertical: 90
  },
  header: {
    fontSize: 34,
    lineHeight: 31,
    fontWeight: 'bold',
    marginBottom: 20,
    color: theme.colors.white
  },
  paragraph: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.white,
    textAlign: 'center'
  },
  paginationWrapper: {
    position: 'absolute',
    bottom: '40%',
    left: 0,
    right: 0,
    justifyContent: 'center',
    alignItems: 'center',
    flexDirection: 'row',
  },
  paginationDots: {
    height: 8,
    width: 8,
    borderRadius: 10 / 2,
    backgroundColor: theme.colors.white,
    marginLeft: 10
  },
  unDot: {
    borderStyle: 'solid',
    borderWidth: 1,
    borderColor: theme.colors.white,
    backgroundColor: 'transparent'
  }
});

export default GetStartedPage;
