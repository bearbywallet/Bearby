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
  StyleSheet,
  Text,
  TouchableOpacity,
  View
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import Svg, { Path } from 'react-native-svg';

import { fonts } from 'app/styles';

type Prop = {
  value: number;
  onChange: (value: number) => void;
};

export const Indexer: React.FC<Prop> = ({
  value,
  onChange
}) => {
  const { colors } = useTheme();

  const hanldeChange = React.useCallback((v: number) => {
    if (v < 0) {
      return onChange(0);
    }

    return onChange(v);
  }, []);

  return (
    <View style={[styles.incWrapper, {
      backgroundColor: colors['bg1']
    }]}>
      <TouchableOpacity
        style={styles.btn}
        onPress={() => hanldeChange(value - 1)}
      >
        <Svg
          width="30"
          height="2"
          viewBox="0 0 36 2"
          fill="none"
        >
          <Path
            d="M0 1H36"
            stroke={colors.text}
            strokeWidth="2"
          />
        </Svg>
      </TouchableOpacity>
      <Text style={[styles.plusText, {
        color: colors.text
      }]}>
        {String(value)}
      </Text>
      <TouchableOpacity
        style={styles.btn}
        onPress={() => hanldeChange(value + 1)}
      >
        <Svg
          width="30"
          height="30"
          viewBox="0 0 36 36"
          fill="none"
        >
          <Path
            d="M0 17H36M19 0L19 36"
            stroke={colors.text}
            strokeWidth="2"
          />
        </Svg>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  plusText: {
    fontSize: 30,
    fontFamily: fonts.Demi
  },
  btn: {
    minWidth: 30,
    minHeight: 30,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12
  },
  incWrapper: {
    flexDirection: 'row',
    borderRadius: 14,
    justifyContent: 'space-between',
    alignItems: 'center',
    margin: 5
  }
});
