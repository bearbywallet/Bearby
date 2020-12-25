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
  TouchableOpacity,
  ViewStyle
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import { SvgXml } from 'react-native-svg';

import { OKIconSVG } from 'app/components/svg';
import { Unselected } from 'app/components/unselected';

import { theme } from 'app/styles';

type Prop = {
  items: string[];
  title?: string;
  selected: number | string;
  style?: ViewStyle;
  onSelect?: (item: string, index: number) => void;
};

/**
 * Selector an option component.
 * @example
 * import { Selector } from 'app/components/selector';
 * const view = () => (
 *  <Selector
 *    style={{ marginVertical: 16 }}
 *    title={'test'}
 *    items={['option1', 'option2', 'option3']}
 *    selected={'option2'}
 *    onSelect={(option) => console.log(option)}
 *  />
 * );
 */
export const Selector: React.FC<Prop> = ({
  selected,
  title,
  items,
  style,
  onSelect = () => null
}) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.container, style]}>
      <Text style={[styles.title, {
        color: colors.text
      }]}>
        {title}
      </Text>
      {items.map((item, index) => (
        <TouchableOpacity
          key={index}
          style={[styles.item, {
            borderBottomColor: colors.border
          }]}
          onPress={() => onSelect(item, index)}
        >
          {String(selected) === String(item) ? (
            <SvgXml xml={OKIconSVG(colors.primary)} />
          ) : (
            <Unselected />
          )}
          <Text style={[styles.itemText, {
            color: colors.text
          }]}>
            {item}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingTop: 16,
    paddingHorizontal: 16,
    width: '100%'
  },
  title: {
    fontSize: 16,
    lineHeight: 21
  },
  item: {
    borderBottomWidth: 1,
    paddingVertical: 13,
    flexDirection: 'row',
    alignItems: 'center'
  },
  itemText: {
    fontSize: 17,
    lineHeight: 22,
    marginLeft: 16
  }
});
