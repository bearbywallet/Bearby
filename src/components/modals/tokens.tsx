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
  StyleSheet,
  ScrollView,
  Dimensions,
  TouchableOpacity,
  ViewStyle
} from 'react-native';
import Modal from 'react-native-modal';
import { SvgXml, SvgCssUri } from 'react-native-svg';

import { OKIconSVG } from 'app/components/svg';
import { Unselected } from 'app/components/unselected';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';

import { theme } from 'app/styles';
import { TOKEN_ICONS } from 'app/config';
import { Token, Account } from 'types';
import { fromZil } from 'app/filters';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title: string;
  network: string;
  tokens: Token[];
  account: Account;
  selected?: number;
  onTriggered: () => void;
  onSelect: (index: number) => void;
};

const { width } = Dimensions.get('window');
export const TokensModal: React.FC<Prop> = ({
  style,
  visible,
  title,
  selected,
  account,
  tokens,
  network,
  onTriggered,
  onSelect
}) => {
  const handleSelected = React.useCallback((index) => {
    onSelect(index);
    onTriggered();
  }, [onSelect, onTriggered]);

  return (
    <Modal
      isVisible={visible}
      style={{
        justifyContent: 'flex-end',
        margin: 0,
        marginBottom: 1
      }}
      onBackdropPress={onTriggered}
    >
      <ModalWrapper style={style}>
        <ModalTitle onClose={onTriggered}>
          {title}
        </ModalTitle>
        <ScrollView style={styles.main}>
          {tokens.map((token, index) => (
            <TouchableOpacity
              key={index}
              style={[styles.item, {
                borderBottomWidth: index === tokens.length - 1 ? 0 : 1
              }]}
              onPress={() => handleSelected(index)}
            >
              {token.symbol ? (
                <SvgCssUri
                  height="30"
                  width="30"
                  uri={`${TOKEN_ICONS}/${token.symbol}.svg`}
                />
              ) : null}
              <View style={styles.wrapper}>
                <Text style={styles.symbol}>
                  {token.name}
                </Text>
                {token.decimals ? (
                  <Text style={styles.amount}>
                    {fromZil(account.balance[network][token.symbol], token.decimals)} {token.symbol}
                  </Text>
                ) : null}
              </View>
              {selected === index ? (
                <SvgXml xml={OKIconSVG}/>
              ) : (
                <Unselected />
              )}
            </TouchableOpacity>
          ))}
        </ScrollView>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  symbol: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  },
  wrapper: {
    width: width - 100,
    marginLeft: 10
  },
  item: {
    flexDirection: 'row',
    alignSelf: 'flex-start',
    alignItems: 'center',
    width: '100%',
    justifyContent: 'space-between',
    paddingVertical: 15,
    borderBottomColor: theme.colors.black
  },
  amount: {
    color: '#8A8A8F',
    fontSize: 13,
    lineHeight: 17
  },
  main: {
    marginTop: 15
  }
});
