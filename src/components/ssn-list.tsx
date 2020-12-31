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
  View
} from 'react-native';

import { Button } from 'app/components/button';
import { Selector } from 'app/components/selector';

import { SSN, SSNState } from 'types';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  ssnState: SSNState;
  onUpdate: () => void;
  onSelect: (ssn: SSN) => void;
};

export const SSnList: React.FC<Prop> = ({
  style,
  ssnState,
  onSelect,
  onUpdate
}) => {
  const { colors } = useTheme();

  const items = React.useMemo(
    () => ssnState.list.map((ssn) => ssn.name),
    [ssnState]
  );

  const hanldeSelect = React.useCallback((name) => {
    const found = ssnState.list.find((ssn) => ssn.name === name);

    if (!found) {
      return null;
    }

    onSelect(found);
  }, [ssnState]);

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
      <Selector
        items={items}
        selected={ssnState.selected}
        onSelect={hanldeSelect}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
  },
  titleWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 15
  },
  title: {
    fontSize: 17,
    fontFamily: fonts.Bold
  },
  item: {
    flexDirection: 'row'
  }
});
