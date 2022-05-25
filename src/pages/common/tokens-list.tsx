/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */

import type { ServerToken } from 'types';

import React from 'react';
import {
  View,
  Dimensions,
  StyleSheet,
  TextInput,
  Text,
  Alert,
  RefreshControl
} from 'react-native';
import { RouteProp, useTheme } from '@react-navigation/native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import i18n from 'app/lib/i18n';
import { StackNavigationProp } from '@react-navigation/stack';

import { RootParamList } from 'app/navigator';
import { CommonStackParamList } from 'app/navigator/common';

import SearchIconSVG from 'app/assets/icons/search.svg';
import { BrowserCategoryLoading } from 'app/components/browser/category-loading';
import { Switcher } from 'app/components/switcher';
import { Button } from 'app/components/button';
import { LoadSVG } from 'app/components/load-svg';

import { fonts } from 'app/styles';
import { keystore } from 'app/keystore';
import { AddTokenModal } from 'app/components/modals';
import { toBech32Address } from 'app/utils/bech32';
import { ZILLIQA_KEYS } from 'app/config';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
  route: RouteProp<CommonStackParamList, 'Transfer'>;
};

const [mainnet] = ZILLIQA_KEYS;
const { width } = Dimensions.get('window');
const limit = 100;
export const TokensListPage: React.FC<Prop> = ({ route, navigation }) => {
  const { colors } = useTheme();

  const tokensState = keystore.token.store.useValue();
  const accountState = keystore.account.store.useValue();
  const networkState = keystore.network.store.useValue();

  const [loading, setLoading] = React.useState(true);
  const [refreshing, setRefreshing] = React.useState(false);
  const [list, setList] = React.useState<ServerToken[]>([]);
  const [search, setSearch] = React.useState('');
  const [addToken, setAddToken] = React.useState(false);

  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );

  const filteredList = React.useMemo(() => {
    return list.filter((t) => {
      const t1 = String(t.symbol).toLowerCase().includes(String(search).toLowerCase());
      const t2 = String(t.name).toLowerCase().includes(String(search).toLowerCase());

      return (t1 || t2) && t.symbol !== 'ZLP';
    }).map((t) => ({
      ...t,
      selected: tokensState.some((st) => st.symbol === t.symbol)
    }));
  }, [search, list, tokensState]);

  const hanldeUpdate = React.useCallback(async(load: boolean) => {
    if (networkState.selected !== mainnet) {
      setLoading(false);
      return;
    }

    setLoading(true);

    if (load) {
      setRefreshing(true);
    }

    try {
      const res = await keystore.token.loadingFromServer(limit);
      const currentTokens = tokensState.filter((t) => Boolean(t.address[networkState.selected])).slice(1).map((t) => ({
        id: 0,
        bech32: toBech32Address(t.address[networkState.selected]),
        base16: t.address[networkState.selected],
        decimals: t.decimals,
        name: t.name,
        symbol: t.symbol,
        baseUri: null,
        scope: 100,
        type: 1
      }));
      const newList = [];

      for (const token of res.list) {
        const has = currentTokens.some((t) => t.symbol === token.symbol);

        if (has) {
          continue;
        }

        newList.push(token);
      }

      setList([...currentTokens, ...newList]);
    } catch {
      Alert.alert(
        i18n.t('update'),
        'Server Error',
        [
          { text: "OK" }
        ]
      );
    }

    setRefreshing(false);
    setLoading(false);
  }, [list, networkState, tokensState]);

  const hanldeAddToken = React.useCallback(async(token: ServerToken) => {
    const currenAccount = keystore.account.getCurrentAccount();
    const found = tokensState.find((st) => st.symbol === token.symbol);
    try {
      if (found) {
        await keystore.token.removeToken(found);
      } else {
        const foundToken = await keystore.token.getToken(token.base16, currenAccount);
        await keystore.token.addToken(foundToken);
      }
    } catch {
      /////
    }
  }, [tokensState]);

  const hanldeManuallyAddToken = React.useCallback(async(token, cb) => {
    try {
      await keystore.token.addToken(token);

      cb();
    } catch {
      //
    }
  }, []);

  React.useEffect(() => {
    hanldeUpdate(false);
  }, []);

  return (
    <React.Fragment>
      <AddTokenModal
        account={account}
        title={i18n.t('add_token')}
        visible={addToken}
        onTriggered={() => setAddToken(false)}
        onAddToken={hanldeManuallyAddToken}
      />
      <View style={styles.inputWrapper}>
        <SearchIconSVG />
        <TextInput
          style={[styles.textInput, {
            color: colors.text,
            borderBottomColor: colors.border
          }]}
          autoCorrect={false}
          autoCapitalize={'none'}
          textContentType={'URL'}
          placeholder={i18n.t('search_token')}
          placeholderTextColor={colors.border}
          onChangeText={setSearch}
        />
        <Button
          title={i18n.t('add_tokens')}
          color={colors.primary}
          onPress={() => setAddToken(true)}
        />
      </View>
      <KeyboardAwareScrollView
        style={[styles.container, {
          backgroundColor: colors.card
        }]}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => hanldeUpdate(true)}
          />
        }
      >
        {filteredList.map((el, index) => (
          <View
            key={el.base16}
            style={[styles.tokenCard, {
              marginBottom: filteredList.length - 1 === index ? 70 : undefined
            }]}
          >
            <LoadSVG
              addr={el.bech32}
              height="30"
              width="30"
            />
            <Switcher
              style={styles.switcherContainer}
              enabled={el.selected}
              onChange={() => hanldeAddToken(el)}
            >
              <View style={styles.tokenRow}>
                <Text style={[styles.tokenSymbol, {
                  color: colors.text
                }]}>
                  {el.symbol}
                </Text>
                <Text style={[styles.tokenName, {
                  color: colors.border
                }]}>
                  {el.name}
                </Text>
              </View>
            </Switcher>
          </View>
        ))}
        {loading ? (
          <>
            <BrowserCategoryLoading marginBottom={10}/>
            <BrowserCategoryLoading marginBottom={10}/>
            <BrowserCategoryLoading marginBottom={10}/>
          </>
        ) : null}
      </KeyboardAwareScrollView>
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 15,
    borderTopRightRadius: 16,
    borderTopLeftRadius: 16,
    marginTop: 8,
    padding: 16
  },
  textInput: {
    fontSize: 14,
    padding: 5,
    fontFamily: fonts.Demi,
    borderBottomWidth: 1,
    width: width - 150
  },
  inputWrapper: {
    paddingHorizontal: 15,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  tokenCard: {
    paddingHorizontal: 16,
    borderRadius: 8,
    margin: 5,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  tokenName: {
    fontSize: 12,
    fontFamily: fonts.Regular
  },
  tokenSymbol: {
    fontSize: 17,
    fontFamily: fonts.Demi
  },
  tokenRow: {
    paddingHorizontal: 16,
    width: '74%'
  },
  switcherContainer: {
    paddingVertical: 16
  }
});
