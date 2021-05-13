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

  React.useEffect(() => {
    const uri = viewIcon(addr, dark);

    fetch(uri)
      .then((res) => {
        if (res.ok) {
          return res.text();
        }

        return undefined;
      })
      .then((content) => {
        setXml(content ? content : HelpIconSVG());
      })
      .catch(() => {
        setXml(HelpIconSVG());
      });
  }, [addr, dark]);

  return (
    <React.Fragment>
      {xml ? (
        <SvgCss
          width={width}
          height={height}
          xml={xml}
        />
      ) : (
        <ActivityIndicator
          animating={!xml}
          color={colors.primary}
        />
      )}
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
});
