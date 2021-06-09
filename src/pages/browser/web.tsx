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
  View,
  ActivityIndicator
} from 'react-native';
import URL from 'url-parse';
import { WebView } from 'react-native-webview';
import { WebViewProgressEvent } from 'react-native-webview/lib/WebViewTypes';
import FastImage from 'react-native-fast-image';
import { SafeWrapper } from 'app/components/safe-wrapper';

import { BrowserViewBar } from 'app/components/browser';
import {
  ConnectModal,
  SignMessageModal,
  ConfirmPopup
} from 'app/components/modals';

import { RouteProp, useTheme } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';
import { BrwoserStackParamList } from 'app/navigator/browser';
import { keystore } from 'app/keystore';
import { version } from '../../../package.json';
import { Messages } from 'app/config';
import { Message } from 'app/lib/controller/inject/message';
import { Transaction } from 'app/lib/controller/transaction';
import { MessagePayload, TxMessage } from 'types';
import i18n from 'app/lib/i18n';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
  route: RouteProp<BrwoserStackParamList, 'Web'>;
};

const { width } = Dimensions.get('window');
export const WebViewPage: React.FC<Prop> = ({ route, navigation }) => {
  const { colors } = useTheme();
  const inpageJS = keystore.inpage.store.useValue();
  const searchEngineState = keystore.searchEngine.store.useValue();
  const connectState = keystore.connect.store.useValue();
  const accountState = keystore.account.store.useValue();
  const networkState = keystore.network.store.useValue();
  const tokenState = keystore.token.store.useValue();
  const authState = keystore.guard.auth.store.useValue();

  const webViewRef = React.useRef<null | WebView>(null);

  const [url, setUrl] = React.useState(new URL(route.params.url));
  const [urlPach, setUrlPach] = React.useState(url);
  const [loadingProgress, setLoadingProgress] = React.useState(0);
  const [canGoBack, setCanGoBack] = React.useState(false);
  const [canGoForward, setCanGoForward] = React.useState(false);

  const [confirmError, setConfirmError] = React.useState<string>();

  const [appConnect, setAppConnect] = React.useState<MessagePayload>();
  const [signMessage, setSignMessage] = React.useState<MessagePayload>();
  const [transaction, setTransaction] = React.useState<TxMessage>();

  const isConnect = React.useMemo(() => {
    const { hostname } = url;

    return connectState.some(
      (app) => app.domain.toLowerCase() === hostname.toLowerCase()
    );
  }, [connectState, url, urlPach]);
  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );

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
  }, [webViewRef, canGoBack]);
  const handleGoHome = React.useCallback(() => {
    // navigation.navigate('Browser');
    navigation.navigate('Browser', {
      screen: 'Browser'
    });
  }, [navigation]);

  const handleLoaded = React.useCallback(({ nativeEvent }: WebViewProgressEvent) => {
    setLoadingProgress(nativeEvent.progress);
    setCanGoBack(nativeEvent.canGoBack);
    setCanGoForward(nativeEvent.canGoForward);
  }, [setLoadingProgress, setCanGoBack, setCanGoForward]);
  const hanldeRefresh = React.useCallback(() => {
    if (webViewRef.current) {
      webViewRef.current.reload();
    }
  }, [webViewRef]);
  const hanldeSearch = React.useCallback(async(search) => {
    if (!webViewRef || !webViewRef.current) {
      return null;
    }

    const _url = await keystore.searchEngine.onUrlSubmit(search);

    setUrlPach(new URL(_url));
  }, [webViewRef]);
  const hanldeoNavigationStateChange = React.useCallback((event) => {
    setUrl(new URL(event.url));
  }, [url]);

  const handleMessage = React.useCallback(async({ nativeEvent }) => {
    if (!webViewRef.current) {
      return null;
    }

    const net = networkState.selected;

    try {
      const message = JSON.parse(nativeEvent.data);

      switch (message.type) {
        case Messages.init:
          const { base16, bech32 } = keystore.account.getCurrentAccount();
          const m = new Message(Messages.wallet, {
            origin: message.payload.origin,
            data: {
              isConnect,
              account: isConnect ? {
                base16,
                bech32
              } : null,
              isEnable: keystore.guard.isEnable,
              netwrok: net
            }
          });
          webViewRef.current.postMessage(m.serialize);
          break;

        case Messages.appConnect:
          if (isConnect) {
            handleConnect(isConnect, message.payload);
            break;
          }
          setAppConnect(message.payload);
          break;

        case Messages.reqProxy:
          const { method, params } = message.payload.data;
          webViewRef.current.postMessage(new Message(Messages.resProxy, {
            origin: message.payload.origin,
            uuid: message.payload.uuid,
            data: await keystore.zilliqa.throughPxoy(method, params)
          }).serialize);
          break;

        case Messages.signMessage:
          setSignMessage(message.payload);
          break;

        case Messages.signTx:
          setConfirmError(undefined);
          const nonce = await keystore.transaction.calcNextNonce(account);
          const newTX = Transaction.fromPayload(
            message.payload.data,
            account,
            net
          );
          newTX.setNonce(nonce);
          setTransaction({
            params: newTX,
            uuid: message.payload.uuid,
            origin: message.payload.origin,
            icon: message.payload.icon
          });
          break;

        default:
          break;
      }
    } catch (err) {
      // console.error(err);
    }
  }, [
    webViewRef,
    networkState,
    account,
    isConnect
  ]);

  const handleConnect = React.useCallback((value, app?: MessagePayload) => {
    let connector = app;

    if (appConnect) {
      connector = appConnect;
    }

    if (value && connector && connector.title && connector.icon && connector.origin) {
      keystore.connect.add({
        title: connector.title,
        domain: new URL(connector.origin).hostname,
        icon: connector.icon
      });
    }

    if (webViewRef.current && connector) {
      const { base16, bech32 } = keystore.account.getCurrentAccount();
      const m = new Message(Messages.resConnect, {
        origin: connector.origin,
        uuid: connector.uuid,
        data: {
          confirm: value,
          account: value ? {
            base16,
            bech32
          } : null
        }
      });
      webViewRef.current.postMessage(m.serialize);
    }
    setAppConnect(undefined);
  }, [appConnect, webViewRef]);

  const handleSignMessage = React.useCallback((value) => {
    if (!webViewRef.current || !signMessage?.origin || !signMessage?.uuid) {
      return null;
    }

    const data: {
      reject: undefined | string;
      resolve: undefined | object;
    } = {
      reject: undefined,
      resolve: undefined
    };

    if (!value) {
      data.reject = 'User rejected';
    } else if (value) {
      data.resolve = value;
    }

    const m = new Message(Messages.signResult, {
      origin: signMessage.origin,
      uuid: signMessage.uuid,
      data
    });
    webViewRef.current.postMessage(m.serialize);
    setSignMessage(undefined);
  }, [webViewRef, signMessage, setSignMessage]);
  /**
   * Confirm and send transaction from popup.
   */
  const handleConfirmTransaction = React.useCallback(async(tx: Transaction, cb, password) => {
    setConfirmError(undefined);

    if (!webViewRef.current || !transaction) {
      return null;
    }

    try {
      const chainID = await keystore.zilliqa.getNetworkId();
      const keyPair = await keystore.getkeyPairs(account, password);

      tx.setVersion(chainID);
      await tx.sign(keyPair.privateKey);
      tx.hash = await keystore.zilliqa.send(tx);

      await keystore.transaction.add(tx);

      const m = new Message(Messages.signResult, {
        origin: transaction.origin,
        uuid: transaction.uuid,
        data: {
          resolve: {
            ID: tx.hash,
            ...tx.self
          }
        }
      });
      webViewRef.current.postMessage(m.serialize);

      cb();
      setTransaction(undefined);
    } catch (err) {
      cb();
      setConfirmError(err.message);
    }
  }, [
    accountState,
    transaction,
    webViewRef
  ]);
  /**
   * Reject the transaction, from popup.
   */
  const hanldeRejectTransaction = React.useCallback(() => {
    if (!webViewRef.current || !transaction) {
      return null;
    }

    const m = new Message(Messages.signResult, {
      origin: transaction.origin,
      uuid: transaction.uuid,
      data: {
        reject: 'User rejected'
      }
    });
    webViewRef.current.postMessage(m.serialize);
    setTransaction(undefined);
  }, [transaction]);

  /**
   * Sync if inject page script didn't load.
   */
  React.useEffect(() => {
    if (!inpageJS) {
      keystore.inpage.sync();
    }
  }, []);

  React.useEffect(() => {
    hanldeSearch(route.params.url);
  }, [route]);

  /**
   * Listing webViewRef when it created, and update
   * network and accounts webView instance for autoupdate
   * selected netwrok and selecte daccount.
   */
  React.useEffect(() => {
    if (webViewRef.current) {
      keystore.account.updateWebView(
        webViewRef.current,
        url.hostname
      );
      keystore.network.updateWebView(
        webViewRef.current,
        url.hostname
      );
      keystore.worker.block.updateWebView(
        webViewRef.current,
        url.hostname
      );
    }

    return () => keystore.account.updateWebView(undefined);
  }, [url, route, webViewRef]);

  /**
   * Listing event when page loaded, send connection information.
   */
  React.useEffect(() => {
    if (webViewRef.current) {
      const { base16, bech32 } = keystore.account.getCurrentAccount();
      const m = new Message(Messages.resConnect, {
        data: {
          isConnect,
          account: isConnect ? {
            base16,
            bech32
          } : null,
          isEnable: keystore.guard.isEnable,
          netwrok: keystore.network.selected
        }
      });
      webViewRef.current.postMessage(m.serialize);
    }
  }, [
    webViewRef,
    accountState,
    networkState,
    isConnect
  ]);

  if (!inpageJS) {
    return null;
  }

  return (
    <SafeWrapper>
      <BrowserViewBar
        url={url}
        connected={isConnect}
        canGoForward={canGoForward}
        onBack={handleBack}
        onHome={handleGoHome}
        onGoForward={handleGoForward}
        onRefresh={hanldeRefresh}
        onSubmit={hanldeSearch}
        onSettings={() => navigation.navigate('SettingsPages', {
          screen: 'BrowserSettings'
        })}
      />
      {loadingProgress !== 1 ? (
        <View style={[styles.loading, {
          width: width * loadingProgress,
          backgroundColor: colors.primary
        }]}/>
      ) : null}
      <WebView
        ref={webViewRef}
        source={{
          uri: urlPach.toString()
        }}
        style={{
          backgroundColor: colors.background
        }}
        applicationNameForUserAgent={`ZilPay/${version}`}
        incognito={searchEngineState.incognito}
        injectedJavaScriptBeforeContentLoaded={inpageJS}
        cacheEnabled={searchEngineState.cache}
        renderLoading={() => (
          <ActivityIndicator
            color={colors.primary}
            size='large'
            style={{
              flex: 1
            }}
          />
        )}
        onNavigationStateChange={hanldeoNavigationStateChange}
        onMessage={handleMessage}
        onLoadProgress={handleLoaded}
      />
      {appConnect ? (
        <ConnectModal
          app={appConnect}
          visible={Boolean(appConnect)}
          onTriggered={() => handleConnect(false)}
          onConfirm={() => handleConnect(true)}
        />
      ) : null}
      <SignMessageModal
        title={i18n.t('sign_request')}
        visible={Boolean(signMessage)}
        icon={signMessage?.icon || ''}
        account={account}
        needPassword={!authState.biometricEnable}
        appTitle={signMessage?.title || ''}
        payload={String(signMessage?.data)}
        onTriggered={() => setSignMessage(undefined)}
        onSign={handleSignMessage}
      />
      {transaction ? (
        <ConfirmPopup
          transaction={transaction.params}
          token={tokenState[0]}
          account={account}
          error={confirmError || ''}
          title={i18n.t('confirm')}
          needPassword={!authState.biometricEnable}
          visible={Boolean(transaction)}
          onTriggered={hanldeRejectTransaction}
          onConfirm={handleConfirmTransaction}
        >
          <FastImage
            style={{
              height: 30,
              width: 30
            }}
            source={{ uri: transaction.icon }}
          />
        </ConfirmPopup>
      ) : null}
    </SafeWrapper>
  );
};
const styles = StyleSheet.create({
  loading: {
    height: 3
  }
});

export default WebViewPage;
