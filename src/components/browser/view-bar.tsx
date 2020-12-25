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
  Dimensions,
  Text
} from 'react-native';
import URL from 'url-parse';
import { useTheme } from '@react-navigation/native';

import { SvgXml } from 'react-native-svg';
import { ArrowIconSVG, LockSVG } from 'app/components/svg';

type Prop = {
  url: URL;
  canGoForward: boolean;
  onBack: () => void;
  onGoForward: () => void;
};

const { width } = Dimensions.get('window');
export const BrowserViewBar: React.FC<Prop> = ({
  url,
  canGoForward,
  onBack,
  onGoForward
}) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.nav, {
      backgroundColor: colors.background
    }]}>
      <View style={styles.navBtns}>
        <TouchableOpacity onPress={onBack}>
          <SvgXml
            xml={ArrowIconSVG}
            height="30"
            width="30"
            fill={colors.primary}
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
            fill={canGoForward ? colors.primary : colors.notification}
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
          fill={url.protocol.includes('https') ? colors.text : colors['danger']}
        />
        <Text style={[styles.host, {
          color: colors.text
        }]}>
          {url.hostname}
        </Text>
      </View>
      <TouchableOpacity
        style={styles.dotsWrapper}
      >
        <View style={[styles.dot, {
          backgroundColor: colors.primary
        }]}/>
        <View style={[styles.dot, {
          backgroundColor: colors.primary
        }]}/>
        <View style={[styles.dot, {
          backgroundColor: colors.primary
        }]}/>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  nav: {
    height: 50,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around'
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
    fontWeight: 'bold',
    fontSize: 17,
    lineHeight: 22,
    minWidth: width / 3
  },
  dotsWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    height: '100%',
    width: 15
  },
  dot: {
    borderRadius: 100,
    height: 5,
    width: 5,
    marginLeft: 3
  }
});
