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
import { theme } from 'app/styles';
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
    <View style={[styles.container, style]}>
    <View>
      <Text style={styles.labelInput}>
        {i18n.t('netwrok_node')}
      </Text>
      <TextInput
        style={styles.textInput}
        defaultValue={http}
        editable={disabled}
        onChangeText={hanldeChangeNode}
      />
    </View>
    <View style={{ marginTop: 15 }}>
      <Text style={styles.labelInput}>
        {i18n.t('netwrok_ws')}
      </Text>
      <TextInput
        style={styles.textInput}
        editable={disabled}
        defaultValue={ws}
        onChangeText={hanldeChangeWS}
      />
    </View>
    <View style={{ marginTop: 15 }}>
      <Text style={styles.labelInput}>
        {i18n.t('netwrok_msg')}
      </Text>
      <TextInput
        style={styles.textInput}
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
    backgroundColor: theme.colors.gray,
    padding: 15
  },
  labelInput: {
    fontSize: 17,
    lineHeight: 22,
    color: '#8A8A8F'
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    paddingTop: 10,
    padding: 5,
    borderBottomColor: theme.colors.black,
    borderBottomWidth: 1,
    color: theme.colors.white
  },
});
