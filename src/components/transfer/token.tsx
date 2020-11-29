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
  TouchableOpacity,
  Dimensions
} from 'react-native';
import { SvgXml, SvgCssUri } from 'react-native-svg';

import {
  ArrowIconSVG,
  WalletIconSVG
} from 'app/components/svg';
import { TokensModal } from 'app/components/modals';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { fromZil, toConversion } from 'app/filters';
import { Token, Account } from 'types';
import { TOKEN_ICONS } from 'app/config';

import styles from './styles';

type Prop = {
  tokens: Token[];
  account: Account;
  selected: number;
  netwrok: string;
  onSelect: (index: number) => void;
};

const { width } = Dimensions.get('window');
export const TransferToken: React.FC<Prop> = ({
  tokens,
  selected,
  account,
  netwrok,
  onSelect
}) => {
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();

  const [tokenModal, setTokenModal] = React.useState(false);

  const token = React.useMemo(
    () => tokens[selected],
    [tokens, selected]
  );
  const converted = React.useMemo(() => {
    const { decimals, symbol } = token;
    const balance = account.balance[netwrok][symbol];
    const rate = settingsState.rate[currencyState];
    const convert = toConversion(balance, rate, decimals);

    return `${convert} ${currencyState}`;
  }, [token, selected, netwrok, currencyState]);

  return (
    <React.Fragment>
      <TouchableOpacity
        style={styles.item}
        onPress={() => setTokenModal(true)}
      >
        <SvgXml xml={WalletIconSVG} />
        <View style={styles.itemInfo}>
          <Text style={styles.label}>
            {i18n.t('token')}
          </Text>
          <View style={{ flexDirection: 'row' }}>
            <SvgCssUri
              height="30"
              width="30"
              uri={`${TOKEN_ICONS}/${token.symbol}.svg`}
            />
            <View style={{ marginLeft: 5 }}>
              <View style={[styles.infoWrapper, { width: width - 120 }]}>
                <Text style={styles.nameAmountText}>
                  {token.symbol}
                </Text>
                <Text style={styles.nameAmountText}>
                  {fromZil(account.balance[netwrok][token.symbol], token.decimals)}
                </Text>
              </View>
              <View style={[styles.infoWrapper, {
                marginBottom: 15,
                width: width - 120
              }]}>
                <Text style={styles.addressAmount}>
                  {token.name}
                </Text>
                <Text style={styles.addressAmount}>
                  {converted}
                </Text>
              </View>
            </View>
          </View>
        </View>
        <SvgXml
          xml={ArrowIconSVG}
          fill="#666666"
          style={styles.arrowIcon}
        />
      </TouchableOpacity>
      <TokensModal
        title={i18n.t('transfer_modal_title0')}
        visible={tokenModal}
        network={netwrok}
        account={account}
        tokens={tokens}
        selected={selected}
        onTriggered={() => setTokenModal(false)}
        onSelect={onSelect}
      />
    </React.Fragment>
  );
};
