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
  ActivityIndicator
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import { SvgCss, SvgCssUri } from 'react-native-svg';

import { HelpIconSVG } from 'app/components/svg';

type Prop = {
  url: string;
  height?: string;
  width?: string;
  onPress?: () => void;
};

export const LoadSVG: React.FC<Prop> = ({ url, height, width }) => {
  const { colors } = useTheme();

  return (
    <SvgCssUri
      width={width}
      height={height}
      uri={url}
    />
  );
};

const styles = StyleSheet.create({
});
