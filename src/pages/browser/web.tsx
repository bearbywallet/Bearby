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
  Text,
  Dimensions,
  TouchableOpacity,
  View
} from 'react-native';
import URL from 'url-parse';
import SafeAreaView from 'react-native-safe-area-view';
import { WebView } from 'react-native-webview';
import { SvgXml } from 'react-native-svg';
import { WebViewProgressEvent } from 'react-native-webview/lib/WebViewTypes';

import {
  ArrowIconSVG,
  LockSVG
} from 'app/components/svg';

import { theme } from 'app/styles';
import { RouteProp } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { BrwoserStackParamList } from 'app/navigator/browser';

type Prop = {
  navigation: StackNavigationProp<BrwoserStackParamList>;
  route: RouteProp<BrwoserStackParamList, 'Web'>;
};

const INJECTED_JAVASCRIPT = `(function() {
  // window.alert('dasdsa')
})();`;

const { width } = Dimensions.get('window');
export const WebViewPage: React.FC<Prop> = ({ route, navigation }) => {
  const webViewRef = React.useRef<null | WebView>(null);

  const [url, setUrl] = React.useState(new URL(route.params.url));
  const [loadingProgress, setLoadingProgress] = React.useState(0);
  const [canGoBack, setCanGoBack] = React.useState(false);
  const [canGoForward, setCanGoForward] = React.useState(false);

  const hanldeback = React.useCallback(() => {
    if (!canGoBack) {
      return navigation.goBack();
    } else if (webViewRef && webViewRef.current) {
      webViewRef.current.goBack();
    }
  }, [canGoBack, webViewRef]);
  const hanldeGoForward = React.useCallback(() => {
    if (webViewRef && webViewRef.current) {
      webViewRef.current.goForward();
    }
  }, [canGoBack]);

  const handleLoaded = React.useCallback(({ nativeEvent }: WebViewProgressEvent) => {
    setLoadingProgress(nativeEvent.progress);
    setCanGoBack(nativeEvent.canGoBack);
    setCanGoForward(nativeEvent.canGoForward);
  }, [setLoadingProgress, setCanGoBack, setCanGoForward]);

  const handleMessage = React.useCallback((event) => {
    //
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.nav}>
        <View style={styles.navBtns}>
          <TouchableOpacity onPress={hanldeback}>
            <SvgXml
              xml={ArrowIconSVG}
              height="30"
              width="30"
              fill={theme.colors.primary}
              style={{
                transform: [{ rotate: '90deg' }]
              }}
            />
          </TouchableOpacity>
          <TouchableOpacity
            disabled={!canGoForward}
            onPress={hanldeGoForward}
          >
            <SvgXml
              xml={ArrowIconSVG}
              height="30"
              width="30"
              fill={canGoForward ? theme.colors.primary : theme.colors.muted}
              style={{
                transform: [{ rotate: '-90deg' }],
                marginLeft: 15
              }}
            />
          </TouchableOpacity>
        </View>
        <View style={styles.hostWrapper}>
          <SvgXml
            xml={LockSVG}
            height="15"
            width="15"
            fill={url.protocol.includes('https') ? theme.colors.white : theme.colors.danger}
          />
          <Text style={styles.host}>
            {url.hostname}
          </Text>
        </View>
        <TouchableOpacity
          style={styles.dotsWrapper}
        >
          <View style={styles.dot}/>
          <View style={styles.dot}/>
          <View style={styles.dot}/>
        </TouchableOpacity>
      </View>
      {loadingProgress !== 1 ? (
        <View style={[styles.loading, { width: width * loadingProgress }]}/>
      ) : null}
      <WebView
        ref={webViewRef}
        source={{
          uri: route.params.url
        }}
        injectedJavaScriptBeforeContentLoaded={INJECTED_JAVASCRIPT}
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
  nav: {
    height: 50,
    backgroundColor: theme.colors.black,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
    paddingHorizontal: 15
  },
  navBtns: {
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  loading: {
    height: 3,
    backgroundColor: theme.colors.primary
  },
  hostWrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  host: {
    color: theme.colors.white,
    fontWeight: 'bold',
    fontSize: 17,
    lineHeight: 22
  },
  dotsWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    height: '100%',
    width: 15
  },
  dot: {
    backgroundColor: theme.colors.primary,
    borderRadius: 100,
    height: 5,
    width: 5,
    marginLeft: 3
  }
});

export default WebViewPage;
