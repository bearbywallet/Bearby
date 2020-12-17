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
  Dimensions,
  View
} from 'react-native';
import LottieView from 'lottie-react-native';
import URL from 'url-parse';
import SafeAreaView from 'react-native-safe-area-view';
import { WebView } from 'react-native-webview';
import { WebViewProgressEvent } from 'react-native-webview/lib/WebViewTypes';

import { BrowserViewBar } from 'app/components/browser';

import { theme } from 'app/styles';
import { RouteProp } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { BrwoserStackParamList } from 'app/navigator/browser';
import { keystore } from 'app/keystore';
import { version } from '../../../package.json';

type Prop = {
  navigation: StackNavigationProp<BrwoserStackParamList>;
  route: RouteProp<BrwoserStackParamList, 'Web'>;
};

const { width } = Dimensions.get('window');
export const WebViewPage: React.FC<Prop> = ({ route, navigation }) => {
  const inpageJS = keystore.inpage.store.useValue();
  const searchEngineState = keystore.searchEngine.store.useValue();
  const webViewRef = React.useRef<null | WebView>(null);

  const [url] = React.useState(new URL(route.params.url));
  const [loadingProgress, setLoadingProgress] = React.useState(0);
  const [canGoBack, setCanGoBack] = React.useState(false);
  const [canGoForward, setCanGoForward] = React.useState(false);

  const handleBack = React.useCallback(() => {
    if (!canGoBack) {
      return navigation.goBack();
    } else if (webViewRef && webViewRef.current) {
      webViewRef.current.goBack();
    }
  }, [canGoBack, webViewRef]);
  const handleGoForward = React.useCallback(() => {
    if (webViewRef && webViewRef.current) {
      webViewRef.current.goForward();
    }
  }, [canGoBack]);

  const handleLoaded = React.useCallback(({ nativeEvent }: WebViewProgressEvent) => {
    setLoadingProgress(nativeEvent.progress);
    setCanGoBack(nativeEvent.canGoBack);
    setCanGoForward(nativeEvent.canGoForward);
  }, [setLoadingProgress, setCanGoBack, setCanGoForward]);

  const handleMessage = React.useCallback(({ nativeEvent }) => {
    try {
      const message = JSON.parse(nativeEvent.data);

      if (webViewRef.current) {
        keystore.inpage.onMessage(message, webViewRef.current);
      }
    } catch (err) {
      console.error(err);
    }
  }, [webViewRef]);

  React.useEffect(() => {
    if (!inpageJS) {
      keystore.inpage.sync();
    }
  }, [inpageJS]);

  if (!inpageJS) {
    return (
      <SafeAreaView style={{
        flex: 1,
        backgroundColor: '#09090c'
      }}>
        <LottieView
          source={require('app/assets/loader')}
          autoPlay
          loop
        />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <BrowserViewBar
        url={url}
        canGoForward={canGoForward}
        onBack={handleBack}
        onGoForward={handleGoForward}
      />
      {loadingProgress !== 1 ? (
        <View style={[styles.loading, { width: width * loadingProgress }]}/>
      ) : null}
      <WebView
        ref={webViewRef}
        source={{
          uri: route.params.url
        }}
        applicationNameForUserAgent={`ZilPay/${version}`}
        incognito={searchEngineState.incognito}
        injectedJavaScriptBeforeContentLoaded={inpageJS}
        onMessage={handleMessage}
        onLoadProgress={handleLoaded}
      />
    </SafeAreaView>
  );
};
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  loading: {
    height: 3,
    backgroundColor: theme.colors.primary
  }
});

export default WebViewPage;
