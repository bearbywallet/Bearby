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
import { SvgXml } from 'react-native-svg';
import { useTheme } from '@react-navigation/native';

import { OKIconSVG } from 'app/components/svg';
import { Unselected } from 'app/components/unselected';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { LoadSVG } from 'app/components/load-svg';

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
  const { colors, dark } = useTheme();
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
      backdropColor={dark ? '#ffffff5' : '#00000060'}
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
                borderBottomWidth: index === tokens.length - 1 ? 0 : 1,
                borderBottomColor: colors.border
              }]}
              onPress={() => handleSelected(index)}
            >
              {token.symbol ? (
                <LoadSVG
                  height="30"
                  width="30"
                  url={`${TOKEN_ICONS}/${token.symbol}.svg`}
                />
              ) : null}
              <View style={styles.wrapper}>
                <Text style={[styles.symbol, {
                  color: colors.text
                }]}>
                  {token.name}
                </Text>
                {token.decimals ? (
                  <Text style={[styles.amount, {
                    color: colors.border
                  }]}>
                    {fromZil(account.balance[network][token.symbol], token.decimals)} {token.symbol}
                  </Text>
                ) : null}
              </View>
              {selected === index ? (
                <SvgXml xml={OKIconSVG(colors.primary)}/>
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
    paddingVertical: 15
  },
  amount: {
    fontSize: 13,
    lineHeight: 17
  },
  main: {
    marginTop: 15
  }
});
