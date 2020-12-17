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
  TouchableOpacity,
  View,
  Text
} from 'react-native';
import URL from 'url-parse';

import { theme } from 'app/styles';
import { SvgXml } from 'react-native-svg';
import { ArrowIconSVG, LockSVG } from 'app/components/svg';

type Prop = {
  url: URL;
  canGoForward: boolean;
  onBack: () => void;
  onGoForward: () => void;
};

export const BrowserViewBar: React.FC<Prop> = ({
  url,
  canGoForward,
  onBack,
  onGoForward
}) => {
  return (
    <View style={styles.nav}>
      <View style={styles.navBtns}>
        <TouchableOpacity onPress={onBack}>
          <SvgXml
            xml={ArrowIconSVG}
            height="30"
            width="30"
            fill={theme.colors.primary}
            style={{
              transform: [{ rotate: '90deg' }]
            }}
          />
        </TouchableOpacity>
        <TouchableOpacity
          disabled={!canGoForward}
          onPress={onGoForward}
        >
          <SvgXml
            xml={ArrowIconSVG}
            height="30"
            width="30"
            fill={canGoForward ? theme.colors.primary : theme.colors.muted}
            style={{
              transform: [{ rotate: '-90deg' }],
              marginLeft: 15
            }}
          />
        </TouchableOpacity>
      </View>
      <View style={styles.hostWrapper}>
        <SvgXml
          xml={LockSVG}
          height="15"
          width="15"
          fill={url.protocol.includes('https') ? theme.colors.white : theme.colors.danger}
        />
        <Text style={styles.host}>
          {url.hostname}
        </Text>
      </View>
      <TouchableOpacity
        style={styles.dotsWrapper}
      >
        <View style={styles.dot}/>
        <View style={styles.dot}/>
        <View style={styles.dot}/>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  nav: {
    height: 50,
    backgroundColor: theme.colors.black,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
    paddingHorizontal: 15
  },
  navBtns: {
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  hostWrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  host: {
    color: theme.colors.white,
    fontWeight: 'bold',
    fontSize: 17,
    lineHeight: 22
  },
  dotsWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    height: '100%',
    width: 15
  },
  dot: {
    backgroundColor: theme.colors.primary,
    borderRadius: 100,
    height: 5,
    width: 5,
    marginLeft: 3
  }
});
