/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { useTheme } from '@react-navigation/native';
import React from 'react';
import {
  Text,
  StyleSheet,
  ViewStyle,
  ActivityIndicator,
  Dimensions,
  TouchableOpacity,
  View
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import { Button } from 'app/components/button';
import { Unselected } from 'app/components/unselected';
import { OKIconSVG } from 'app/components/svg';

import { SSN, SSNState } from 'types';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  ssnState: SSNState;
  isLoading?: boolean;
  onUpdate: () => void;
  onSelect: (ssn: SSN) => void;
};
const timing = 700;
const { width } = Dimensions.get('window');
export const SSnList: React.FC<Prop> = ({
  style,
  ssnState,
  isLoading,
  onSelect,
  onUpdate
}) => {
  const { colors } = useTheme();

  const SSNList = React.useMemo(
    () => ssnState.list.sort((a, b) => a.time - b.time),
    [ssnState]
  );

  return (
    <View style={[styles.container, style]}>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('ssn')}
        </Text>
        <Button
          color={colors.primary}
          title={i18n.t('update')}
          onPress={onUpdate}
        />
      </View>
      {!isLoading ? (
        <View style={[styles.container, style]}>
          {SSNList.map((item, index) => (
            <TouchableOpacity
              key={index}
              style={[styles.item, {
                borderBottomColor: colors.border,
                borderBottomWidth: index === ssnState.list.length - 1 ? 0 : 1
              }]}
              onPress={() => onSelect(item)}
            >
              {ssnState.selected === item.name ? (
                <SvgXml xml={OKIconSVG(colors.primary)} />
              ) : (
                <Unselected />
              )}
              <View style={styles.ssnEl}>
                <Text style={[styles.itemText, {
                  color: item.time <= timing ? colors.text : colors['warning']
                }]}>
                  {item.name}
                </Text>
                <Text style={[styles.itemText, {
                  color: item.time <= timing ? colors.text : colors['warning']
                }]}>
                  {Math.floor(item.time)} ms
                </Text>
              </View>
            </TouchableOpacity>
          ))}
        </View>
      ) : (
        <ActivityIndicator
          animating={isLoading}
          color={colors.primary}
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%'
  },
  ssnEl: {
    width: width - 40,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  titleWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 15
  },
  item: {
    paddingVertical: 13,
    flexDirection: 'row',
    alignItems: 'center'
  },
  itemText: {
    fontSize: 17,
    fontFamily: fonts.Regular,
    marginLeft: 16
  },
  title: {
    fontSize: 17,
    fontFamily: fonts.Bold
  }
});
