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
  TouchableOpacity,
  ViewStyle
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import Modal from 'react-native-modal';
import { SvgXml } from 'react-native-svg';

import { ModalTitle } from 'app/components/modal-title';
import { OKIconSVG } from 'app/components/svg';
import { Unselected } from 'app/components/unselected';

import i18n from 'app/lib/i18n';
import { TxStatsues } from 'app/config';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  selected: number;
  title: string;
  onTriggered: () => void;
  onSelect: (status: number) => void;
};

export const statuses = ['all', ...Object.keys(TxStatsues)];
export const HistoryStatus: React.FC<Prop> = ({
  style,
  visible,
  selected,
  title,
  onTriggered,
  onSelect
}) => {
  const { colors } = useTheme();
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
      <View style={[styles.modalContainer, {
        backgroundColor: colors.background
      }]}>
        <View style={[styles.modalContainer, style]}>
          <ModalTitle onClose={onTriggered}>
            {title}
          </ModalTitle>
        </View>
        <ScrollView>
          {statuses.map((status, index) => (
            <TouchableOpacity
              key={index}
              style={[styles.statusItem, {
                borderBottomWidth: (index !== statuses.length - 1) ? 1 : 0,
                borderColor: colors.border
              }]}
              onPress={() => handleSelected(index)}
            >
              <Text style={[styles.textItem, {
                color: colors.text
              }]}>
                {i18n.t(status)}
              </Text>
              {selected === index ? (
                <SvgXml xml={OKIconSVG(colors.primary)}/>
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
    justifyContent: 'space-between',
    paddingVertical: 15
  },
  statusItem: {
    padding: 15,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  textItem: {
    fontSize: 17,
    lineHeight: 22
  }
});
