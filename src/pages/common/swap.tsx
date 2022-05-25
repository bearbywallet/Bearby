/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2021 ZilPay
 */

import type { TokenValue } from 'types/store';

import React from 'react';
import Big from 'big.js';
import {
  RefreshControl,
  StyleSheet,
  TouchableOpacity,
  View
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';

import { CustomButton } from 'app/components/custom-button';
import { SwapInput } from 'app/components/swap';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { SwapIconSVG } from 'app/components/svg/swap';
import { ConfirmPopup, TokensModal } from 'app/components/modals';
import { SwapInfo } from 'app/components/swap/swap-info';
import { SwapAdvanced } from 'app/components/swap/advanced';
import { LoadSVG } from 'app/components/load-svg';

import i18n from 'app/lib/i18n';
import { CommonStackParamList } from 'app/navigator/common';
import { keystore } from 'app/keystore';
import { deppUnlink } from 'app/utils/deep-unlink';
import { GasLimits } from 'app/lib/controller/dex';
import { AccountTypes, NIL_ADDRESS, NIL_ADDRESS_BECH32 } from 'app/config';
import { Transaction } from 'app/lib/controller/transaction';
import { RootParamList } from 'app/navigator';


Big.PE = 99;


type Prop = {
  route: RouteProp<CommonStackParamList, 'SwapPage'>;
  navigation: StackNavigationProp<RootParamList>;
};

let approving = false;
export const SwapPage: React.FC<Prop> = ({ route, navigation }) => {
  const { colors } = useTheme();

  const tokensState = keystore.token.store.useValue();
  const networkState = keystore.network.store.useValue();
  const accountState = keystore.account.store.useValue();
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();
  const gasStore = keystore.gas.store.useValue();
  const dexStore = keystore.dex.store.useValue();
  const authState = keystore.guard.auth.store.useValue();
  const blockNumber = keystore.worker.store.useValue();

  const [loading, setLoading] = React.useState(false);
  const [refreshing, setRefreshing] = React.useState(false);
  const [inputTokenModal, setInputTokenModal] = React.useState(false);
  const [outputTokenModal, setOutputTokenModal] = React.useState(false);
  const [confirmModal, setConfirmModal] = React.useState(false);
  const [pair, setPair] = React.useState<TokenValue[]>([
    {
      value: '0',
      meta: tokensState[0],
      approved: String(0)
    },
    {
      value: '0',
      meta: tokensState[route.params.selectedToken || 1],
      approved: String(0)
    }
  ]);
  const [gasLimit, setGasLimit] = React.useState(GasLimits.SwapExactZILForTokens);
  const [tx, setTx] = React.useState<Transaction>();
  const [confirmError, setConfirmError] = React.useState('');

  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );

  const qaAmount = React.useMemo(() => {
    const [{ meta, value }] = pair;

    return Big(value).mul(keystore.dex.toDecimails(meta.decimals)).round();
  }, [pair]);

  const approved = React.useMemo(() => {
    const [exactToken] = pair;
    if (exactToken.meta.address[networkState.selected] === NIL_ADDRESS) {
      return true;
    }
    const approvals = Big(exactToken.approved);

    return approvals.gte(qaAmount);
  }, [qaAmount, pair, networkState]);

  const disabled = React.useMemo(() => {
    const [{ meta, value }] = pair;

    if (Number(value) === 0) {
      return true;
    }

    const balance = Big(account.balance[networkState.selected][meta.symbol]);

    return balance.lt(qaAmount);
  }, [account, networkState, pair, qaAmount]);


  const handleUpdateApprovals = React.useCallback(async(newPair: TokenValue[]) => {
    const net = networkState.selected;
    const token = newPair[0].meta.address[net];

    if (token === NIL_ADDRESS) {
      return newPair;
    }

    setLoading(true);
    try {
      newPair[0].approved = await keystore.zilliqa.getTokenAllowances(
        token,
        account.base16,
        keystore.dex.contract
      );
      setPair(newPair);
    } catch (err) {
      console.error(err);
    }
    setLoading(false);

    return newPair;
  }, [networkState, account]);

  const hanldeUpdate = React.useCallback(async(newPair: TokenValue[]) => {
    try {
      await keystore.account.balanceUpdate();

      const { amount, gas } = keystore.dex.getRealAmount(newPair);

      newPair[1].value = amount.toString();

      setGasLimit(gas);
    } catch {
      ////
    }

    return newPair;
  }, []);

  const hanldeRefresh = React.useCallback(async() => {
    setRefreshing(true);
    let newPair = deppUnlink<TokenValue[]>(pair);
    newPair = await handleUpdateApprovals(newPair);
    newPair = await hanldeUpdate(newPair);
    setPair(newPair);
    setRefreshing(false);
  }, [pair]);

  const hanldeInput = React.useCallback((value: string) => {
    try {
      const newPair = deppUnlink<TokenValue[]>(pair);
      newPair[0].value = Boolean(value) ? Big(value).toString() : '0';

      const { amount, gas } = keystore.dex.getRealAmount(newPair);

      newPair[1].value = String(amount);

      setPair(newPair);
      setGasLimit(gas);
    } catch {
      ////
    }
  }, [pair]);

  const hanldeOnChose = React.useCallback((index: number) => {
    if (index === 0) {
      setInputTokenModal(true);
    } else {
      setOutputTokenModal(true);
    }
  }, []);

  const hanldeOnSwapPair = React.useCallback(async() => {
    let newPair = deppUnlink<TokenValue[]>(pair).reverse();
    const { amount, gas } = keystore.dex.getRealAmount(newPair);

    newPair[1].value = amount.toString();
    newPair = await handleUpdateApprovals(newPair);

    setPair(newPair);
    setGasLimit(gas);
    }, [pair]);

  const hanldeSelectInput = React.useCallback(async(index: number) => {
    let newPair = deppUnlink<TokenValue[]>(pair);

    newPair[0].meta = tokensState[index];

    if (newPair[1].meta.symbol !== newPair[0].meta.symbol) {
      newPair[0].value = '0';
      newPair[1].value = '0';
      newPair[1].approved = '0';
      newPair[0].approved = '0';
      const { gas } = keystore.dex.getRealAmount(newPair);

      newPair = await handleUpdateApprovals(newPair);
      setPair(newPair);
      setGasLimit(gas);
    }
  }, [tokensState, pair]);

  const hanldeSelectOutput = React.useCallback(async(index: number) => {
    let newPair = deppUnlink<TokenValue[]>(pair);

    newPair[1].meta = tokensState[index];

    if (newPair[1].meta.symbol !== newPair[0].meta.symbol) {
      const { gas } = keystore.dex.getRealAmount(newPair);
      newPair[0].value = '0';
      newPair[1].value = '0';
      newPair[1].approved = '0';
      newPair[0].approved = '0';
      newPair = await handleUpdateApprovals(newPair);
      setPair(newPair);
      setGasLimit(gas);
    }
  }, [tokensState, pair]);

  const hanldeSwap = React.useCallback(async() => {
    setLoading(true);
    try {
      let transaction: Transaction;

      if (approved) {
        transaction = await keystore.dex.swap(pair);
      } else {
        transaction = await keystore.dex.increaseAllowance(pair);
        approving = true;
      }

      setTx(transaction);
      setConfirmModal(true);
    } catch {
      ////
    }
    setLoading(false);
  }, [pair, approved]);

  const handleSiging = React.useCallback(async(transaction: Transaction, cb, password?: string) => {
    setConfirmError('');
    try {
      const chainID = await keystore.zilliqa.getNetworkId();

      transaction.setVersion(chainID);

      if (account.type === AccountTypes.Ledger) {
        await transaction.ledgerSign(account);
      } else {
        const keyPair = await keystore.getkeyPairs(account, password);
        await transaction.sign(keyPair.privateKey);
      }

      const res = await keystore.zilliqa.send(transaction);

      transaction.hash = res.TranID;

      await keystore.transaction.add(transaction, pair[0].meta);

      if (approving) {
        const newTransaction = await keystore.dex.swap(pair);
        setTx(undefined);
        setTx(newTransaction);
        cb();
        approving = false;

        return;
      }

      cb();
      setConfirmModal(false);

      setTimeout(() => {
        navigation.navigate('App', {
          screen: 'History'
        });
      }, 500);
    } catch (err) {
      cb();
      setConfirmError((err as Error).message);
    }
  }, [pair, account]);

  React.useEffect(() => {
    if (!confirmModal) {
      const newPair = deppUnlink<TokenValue[]>(pair);
      hanldeUpdate(newPair)
        .then((p) => setPair(p));
    }
  }, [blockNumber, confirmModal]);

  return (
    <KeyboardAwareScrollView
      style={[styles.container, {
        backgroundColor: colors.background
      }]}
      refreshControl={
        <RefreshControl
          refreshing={refreshing}
          onRefresh={() => hanldeRefresh()}
        />
      }
    >
      <View>
        <SwapInput
          token={pair[0].meta}
          currency={currencyState}
          rate={settingsState.rate[currencyState]}
          net={networkState.selected}
          value={pair[0].value}
          title={i18n.t('you_pay')}
          balance={account.balance[networkState.selected][pair[0].meta.symbol]}
          containerStyles={styles.input}
          onChange={hanldeInput}
          onChose={() => hanldeOnChose(0)}
        />
        <View style={styles.wrapper}>
          <TouchableOpacity onPress={hanldeOnSwapPair}>
            <SvgXml xml={SwapIconSVG(colors.primary)}/>
          </TouchableOpacity>
        </View>
        <SwapInput
          token={pair[1].meta}
          currency={currencyState}
          rate={settingsState.rate[currencyState]}
          net={networkState.selected}
          value={pair[1].value}
          title={i18n.t('you_get')}
          pecrents={[]}
          disabled
          containerStyles={styles.input}
          onChose={() => hanldeOnChose(1)}
        />
      </View>
      <SwapInfo
        pair={pair}
        currency={currencyState}
        gasLimit={gasLimit}
        gasPrice={Number(gasStore.gasPrice)}
        rate={settingsState.rate[currencyState]}
      />
      <View style={styles.advanced}>
        <SwapAdvanced
          slippage={dexStore.slippage}
          blocks={dexStore.blocks}
        />
      </View>
      <CustomButton
        title={approved ? i18n.t('swap') : i18n.t('approve')}
        style={styles.button}
        isLoading={refreshing || loading}
        disabled={disabled}
        onPress={hanldeSwap}
      />
      <TokensModal
        title={i18n.t('you_pay')}
        visible={inputTokenModal}
        network={networkState.selected}
        account={account}
        tokens={tokensState}
        selected={tokensState.findIndex((t) => t.symbol === pair[0].meta.symbol)}
        onTriggered={() => setInputTokenModal(false)}
        onSelect={hanldeSelectInput}
      />
      <TokensModal
        title={i18n.t('you_get')}
        visible={outputTokenModal}
        network={networkState.selected}
        account={account}
        tokens={tokensState}
        selected={tokensState.findIndex((t) => t.symbol === pair[1].meta.symbol)}
        onTriggered={() => setOutputTokenModal(false)}
        onSelect={hanldeSelectOutput}
      />
      {tx ? (
        <ConfirmPopup
          transaction={tx}
          error={confirmError || ''}
          token={pair[0].meta}
          account={account}
          title={i18n.t('confirm')}
          visible={confirmModal}
          needPassword={!authState.biometricEnable && account.type !== AccountTypes.Ledger}
          onTriggered={() => setConfirmModal(false)}
          onConfirm={handleSiging}
        >
          <LoadSVG
            addr={NIL_ADDRESS_BECH32}
            height="30"
            width="30"
          />
        </ConfirmPopup>
      ) : null}
    </KeyboardAwareScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  wrapper: {
    alignItems: 'flex-end',
    paddingHorizontal: 20
  },
  input: {
    marginVertical: 5,
    margin: 10
  },
  button: {
    margin: 10
  },
  advanced: {
    alignItems: 'center'
  }
});
