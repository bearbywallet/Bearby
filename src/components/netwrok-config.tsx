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
  TextInput,
  ViewStyle
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import i18n from 'app/lib/i18n';
import { ZILLIQA } from 'app/config';

type Prop = {
  style?: ViewStyle;
  config: typeof ZILLIQA;
  selected: string;
  onChange?: (config: typeof ZILLIQA) => void;
};

export const NetwrokConfig: React.FC<Prop> = ({
  style,
  config,
  selected,
  onChange = () => null
}) => {
  const { colors } = useTheme();
  const [lastNetwrok] = React.useState(Object.keys(config)[2]);

  const http = React.useMemo(
    () => config[selected].PROVIDER,
    [config, selected]
  );
  const ws = React.useMemo(
    () => config[selected].WS,
    [config, selected]
  );
  const msg = React.useMemo(
    () => String(config[selected].MSG_VERSION),
    [config, selected]
  );
  const disabled = React.useMemo(
    () => selected === lastNetwrok,
    [lastNetwrok, selected]
  );

  const hanldeChangeNode = React.useCallback((value) => {
    const newConfig = config;

    newConfig[lastNetwrok].PROVIDER = value;

    onChange(newConfig);
  }, [config, lastNetwrok]);

  const hanldeChangeWS = React.useCallback((value) => {
    const newConfig = config;

    newConfig[lastNetwrok].WS = value;

    onChange(newConfig);
  }, [config, lastNetwrok]);

  const hanldeChangeMSG = React.useCallback((value) => {
    const newConfig = config;

    newConfig[lastNetwrok].MSG_VERSION = Number(value);

    onChange(newConfig);
  }, [config, lastNetwrok]);

  return (
    <View style={[styles.container, {
      backgroundColor: colors.card
    }, style]}>
    <View>
      <Text style={[styles.labelInput, {
        color: colors.border
      }]}>
        {i18n.t('netwrok_node')}
      </Text>
      <TextInput
        style={[styles.textInput, {
          color: colors.text
        }]}
        autoCorrect={false}
        defaultValue={http}
        editable={disabled}
        onChangeText={hanldeChangeNode}
      />
    </View>
    <View style={{ marginTop: 15 }}>
      <Text style={[styles.labelInput, {
        color: colors.border
      }]}>
        {i18n.t('netwrok_ws')}
      </Text>
      <TextInput
        style={[styles.textInput, {
          borderBottomColor: colors.background,
          color: colors.text
        }]}
        autoCorrect={false}
        editable={disabled}
        defaultValue={ws}
        onChangeText={hanldeChangeWS}
      />
    </View>
    <View style={{ marginTop: 15 }}>
      <Text style={[styles.labelInput, {
        color: colors.border
      }]}>
        {i18n.t('netwrok_msg')}
      </Text>
      <TextInput
        style={[styles.textInput, {
          borderBottomColor: colors.background,
          color: colors.text
        }]}
        autoCorrect={false}
        defaultValue={msg}
        editable={disabled}
        onChangeText={hanldeChangeMSG}
      />
    </View>
  </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 15
  },
  labelInput: {
    fontSize: 17,
    lineHeight: 22
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    paddingTop: 10,
    padding: 5,
    borderBottomWidth: 1
  },
});
