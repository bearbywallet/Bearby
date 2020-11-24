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

import { DeleteIconSVG, OKIconSVG } from 'app/components/svg';
import { Unselected } from 'app/components/unselected';

import { theme } from 'app/styles';
import { TOKEN_ICONS } from 'app/config';
import { Token } from 'types';
import { fromZil } from 'app/filters';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title: string;
  network: string;
  tokens: Token[];
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
      <View style={[styles.modalContainer, style]}>
        <View style={styles.titleWrapper}>
          <Text style={styles.title}>
            {title}
          </Text>
          <TouchableOpacity onPress={onTriggered}>
            <SvgXml xml={DeleteIconSVG}/>
          </TouchableOpacity>
        </View>
        <ScrollView>
          {tokens.map((token, index) => (
            <TouchableOpacity
              key={index}
              style={styles.item}
              onPress={() => handleSelected(index)}
            >
              <SvgCssUri
                height="30"
                width="30"
                uri={`${TOKEN_ICONS}/${token.symbol}.svg`}
              />
              <View style={styles.wrapper}>
                <Text style={styles.symbol}>
                  {token.name}
                </Text>
                <Text style={styles.amount}>
                  {fromZil(token.balance[network], token.decimals)} {token.symbol}
                </Text>
              </View>
              {selected === index ? (
                <SvgXml xml={OKIconSVG}/>
              ) : (
                <Unselected />
              )}
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  modalContainer: {
    paddingHorizontal: 15,
    borderTopEndRadius: 16,
    borderTopStartRadius: 16,
    backgroundColor: '#18191D',
    justifyContent: 'space-between',
    paddingVertical: 15
  },
  title: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  },
  titleWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 15
  },
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
    justifyContent: 'space-between',
    paddingVertical: 15,
    borderBottomColor: theme.colors.black,
    borderBottomWidth: 1
  },
  amount: {
    color: '#8A8A8F',
    fontSize: 13,
    lineHeight: 17
  }
});
