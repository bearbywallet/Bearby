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
  ActivityIndicator
} from 'react-native';
import { SvgCssUri, SvgXml } from 'react-native-svg';

import { HelpIconSVG } from 'app/components/svg';

import { theme } from 'app/styles';

type Prop = {
  url: string;
  height?: string;
  width?: string;
  onPress?: () => void;
};

export const LoadSVG: React.FC<Prop> = ({ url, height, width }) => {
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState(false);

  React.useEffect(() => {
    fetch(url).then((res) => {
      if (res.status !== 200) {
        setError(true);
      }

      setIsLoading(false);
    });
  }, []);

  return isLoading ? (
    <ActivityIndicator
      animating={isLoading}
      color={theme.colors.primary}
    />
  ) : !error ? (
    <SvgCssUri
      width={width}
      height={height}
      uri={url}
    />
  ) : (
    <SvgXml
      xml={HelpIconSVG}
      width={width}
      height={height}
    />
  );
};

const styles = StyleSheet.create({
});
