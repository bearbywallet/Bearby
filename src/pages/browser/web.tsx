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
  StyleSheet
} from 'react-native';
import { WebView } from 'react-native-webview';

import { theme } from 'app/styles';

const INJECTED_JAVASCRIPT = `(function() {
  // window.alert('dasdsa')
})();`;

export const WebViewPage = () => {
  return (
    <WebView
        source={{
          uri: 'https://zilpay.xyz'
        }}
        injectedJavaScriptBeforeContentLoaded={INJECTED_JAVASCRIPT}
        style={styles.container}
      />
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    backgroundColor: theme.colors.black
  }
});

export default WebViewPage;
