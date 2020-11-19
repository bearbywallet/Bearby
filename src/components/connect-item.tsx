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
  Image,
  StyleSheet,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import { DeleteIconSVG } from 'app/components/svg';

import { theme } from 'app/styles';
import { Connect } from 'types';

type Prop = {
  style?: ViewStyle;
  connect: Connect;
  onSelect?: () => void;
  onRemove?: () => void;
};

export const ConnectItem: React.FC<Prop> = ({
  style,
  connect,
  onRemove = () => null,
  onSelect = () => null
}) => {
  const source = React.useMemo(
    () => ({ uri: connect.icon }),
    [connect]
  );

  return (
    <View
      style={[styles.container, style]}
      onTouchEnd={onSelect}
    >
      <View style={styles.wrapper}>
        <Image
          style={styles.icon}
          source={source}
        />
        <Text style={styles.title}>
          {connect.title}
        </Text>
        <SvgXml
          xml={DeleteIconSVG}
          onTouchEnd={onRemove}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: theme.colors.gray
  },
  wrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderBottomColor: '#09090C',
    borderBottomWidth: 1,
    marginLeft: 15,
    padding: 15
  },
  title: {
    textAlign: 'left',
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.white,
    paddingLeft: 15
  },
  icon: {
    width: 23,
    height: 23,
    resizeMode: 'contain'
  }
});
