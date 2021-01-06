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
  Image
} from 'react-native';
import URL from 'url-parse';
import SafeAreaView from 'react-native-safe-area-view';
import { WebView } from 'react-native-webview';
import { WebViewProgressEvent } from 'react-native-webview/lib/WebViewTypes';

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

type Prop = {
  navigation: StackNavigationProp<BrwoserStackParamList>;
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

  const [url] = React.useState(new URL(route.params.url));
  const [loadingProgress, setLoadingProgress] = React.useState(0);
  const [canGoBack, setCanGoBack] = React.useState(false);
  const [canGoForward, setCanGoForward] = React.useState(false);

  const [confirmError, setConfirmError] = React.useState<string>();

  const [appConnect, setAppConnect] = React.useState<MessagePayload>();
  const [signMessage, setSignMessage] = React.useState<MessagePayload>();
  const [transaction, setTransaction] = React.useState<TxMessage>();

  const isConnect = React.useMemo(() => {
    const { hostname } = new URL(route.params.url);

    return connectState.some(
      (app) => app.domain.toLowerCase() === hostname.toLowerCase()
    );
  }, [connectState, route.params.url]);
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
    navigation.navigate('Browser', {});
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

  const handleMessage = React.useCallback(async({ nativeEvent }) => {
    if (!webViewRef.current) {
      return null;
    }

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
              netwrok: keystore.network.selected
            }
          });
          webViewRef.current.postMessage(m.serialize);
          break;

        case Messages.appConnect:
          if (isConnect) {
            handleConnect(isConnect);
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
          setTransaction({
            params: Transaction.fromPayload(message.payload.data, account),
            uuid: message.payload.uuid,
            origin: message.payload.origin,
            icon: message.payload.icon
          });
          break;

        default:
          break;
      }
    } catch (err) {
      console.error(err);
    }
  }, [
    webViewRef,
    account,
    isConnect
  ]);

  const handleConnect = React.useCallback((value) => {
    if (value && appConnect && appConnect.title && appConnect.icon && appConnect.origin) {
      keystore.connect.add({
        title: appConnect.title,
        domain: new URL(appConnect.origin).hostname,
        icon: appConnect.icon
      });
    }

    if (webViewRef.current && appConnect) {
      const { base16, bech32 } = keystore.account.getCurrentAccount();
      const m = new Message(Messages.resConnect, {
        origin: appConnect.origin,
        uuid: appConnect.uuid,
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
  const handleConfirmTransaction = React.useCallback(async(tx: Transaction, cb, password) => {
    setConfirmError(undefined);

    if (!webViewRef.current || !transaction) {
      return null;
    }

    try {
      await keystore.account.updateNonce(accountState.selectedAddress);
      const chainID = await keystore.zilliqa.getNetworkId();
      const keyPair = await keystore.getkeyPairs(account, password);

      tx.setVersion(chainID);
      tx.nonce = account.nonce + 1;
      await tx.sign(keyPair.privateKey);
      tx.hash = await keystore.zilliqa.send(tx);

      await keystore.account.increaseNonce(accountState.selectedAddress);
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

  React.useEffect(() => {
    if (!inpageJS) {
      keystore.inpage.sync();
    }
  }, []);

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
  }, [webViewRef, accountState, networkState, isConnect]);

  if (!inpageJS) {
    return null;
  }

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <BrowserViewBar
        url={url}
        canGoForward={canGoForward}
        onBack={handleBack}
        onHome={handleGoHome}
        onGoForward={handleGoForward}
        onRefresh={hanldeRefresh}
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
          uri: route.params.url
        }}
        applicationNameForUserAgent={`ZilPay/${version}`}
        incognito={searchEngineState.incognito}
        injectedJavaScriptBeforeContentLoaded={inpageJS}
        cacheEnabled={false}
        onMessage={handleMessage}
        onLoadProgress={handleLoaded}
      />
      <ConnectModal
        app={appConnect}
        visible={Boolean(appConnect)}
        onTriggered={() => handleConnect(false)}
        onConfirm={() => handleConnect(true)}
      />
      <SignMessageModal
        title={i18n.t('sign_request')}
        visible={Boolean(signMessage)}
        icon={signMessage?.icon}
        account={account}
        needPassword={!authState.biometricEnable}
        appTitle={signMessage?.title}
        payload={String(signMessage?.data)}
        onTriggered={() => setSignMessage(undefined)}
        onSign={handleSignMessage}
      />
      {transaction ? (
        <ConfirmPopup
          transaction={transaction.params}
          token={tokenState[0]}
          account={account}
          error={confirmError}
          title={i18n.t('confirm')}
          needPassword={!authState.biometricEnable}
          visible={Boolean(transaction)}
          onTriggered={hanldeRejectTransaction}
          onConfirm={handleConfirmTransaction}
        >
          <Image
            style={{
              height: 30,
              width: 30
            }}
            source={{ uri: transaction.icon }}
          />
        </ConfirmPopup>
      ) : null}
    </SafeAreaView>
  );
};
const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  loading: {
    height: 3
  }
});

export default WebViewPage;
