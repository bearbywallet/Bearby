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
import { SvgCss } from 'react-native-svg';
import FastImage from 'react-native-fast-image';

import HelpIconSVG from 'app/assets/icons/help.svg';

import { viewIcon } from 'app/utils';

type Prop = {
  addr: string;
  height?: string;
  width?: string;
  onPress?: () => void;
};

export const LoadSVG: React.FC<Prop> = ({ addr, height, width }) => {
  const { dark, colors } = useTheme();
  const [xml, setXml] = React.useState<string | null>(null);
  const [url, setUrl] = React.useState<string | null>(null);

  React.useEffect(() => {
    const uri = viewIcon(addr, dark);

    fetch(uri)
      .then((res) => {
        const type = String(res.headers['map']['content-type']);

        if (!res.ok) {
          return null;
        } else if (type.includes('svg')) {
          return res.text();
        } else if (type.includes('png')) {
          setUrl(uri);
        }

        return null;
      })
      .then((content) => {
        setXml(content ? content : HelpIconSVG());
      })
      .catch(() => {
        setXml(HelpIconSVG());
      });
  }, [addr, dark]);

  if (url) {
    return (
      <FastImage
        source={{ uri: url }}
        style={{
          width: Number(width),
          height: Number(height)
        }}
      />
    );
  }

  if (xml) {
    return (
      <SvgCss
        width={width}
        height={height}
        xml={xml}
      />
    );
  }

  return (
    <ActivityIndicator
      animating={true}
      color={colors.primary}
    />
  );
};

const styles = StyleSheet.create({
});
