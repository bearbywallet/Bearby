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
  TouchableOpacity,
  ViewStyle
} from 'react-native';
import Modal from 'react-native-modal';
import { SvgXml } from 'react-native-svg';

import { CustomButton } from 'app/components/custom-button';
import { DeleteIconSVG } from 'app/components/svg';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { keystore } from 'app/keystore';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title: string;
  btnTitle: string;
  onTriggered: () => void;
  onConfirmed: (passowrd: string) => void;
};
export const PasswordModal: React.FC<Prop> = ({
  style,
  visible,
  title,
  btnTitle,
  onTriggered,
  onConfirmed
}) => {
  const [passowrd, setPassowrd] = React.useState<string>('');
  const [errorMessage, setErrorMessage] = React.useState<string>(' ');

  const hanldeConfirm = React.useCallback(async() => {
    try {
      await keystore.guard.unlock(passowrd);

      onConfirmed(passowrd);
    } catch (err) {
      setErrorMessage(i18n.t('lock_error'));
    }
  }, [passowrd]);
  const hanldeChangePassword = React.useCallback((value) => {
    setErrorMessage(' ');
    setPassowrd(value);
  }, []);

  return (
    <Modal
      isVisible={visible}
      style={{
        justifyContent: 'flex-end',
        margin: 0
      }}
      onBackdropPress={onTriggered}
    >
      <View style={[styles.container, style]}>
        <View style={styles.titleWrapper}>
          <Text style={styles.title}>
            {title}
          </Text>
          <TouchableOpacity onPress={onTriggered}>
            <SvgXml xml={DeleteIconSVG}/>
          </TouchableOpacity>
        </View>
        <View>
          <TextInput
            style={styles.textInput}
            secureTextEntry={true}
            placeholder={i18n.t('pass_setup_input1')}
            placeholderTextColor="#8A8A8F"
            onSubmitEditing={hanldeConfirm}
            onChangeText={hanldeChangePassword}
          />
          <Text style={styles.error}>
            {errorMessage}
          </Text>
        </View>
        <CustomButton
          title={btnTitle}
          onPress={hanldeConfirm}
        />
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 15,
    borderRadius: 16,
    backgroundColor: '#18191D',
    height: '25%',
    justifyContent: 'space-between',
    paddingVertical: 30
  },
  titleWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  inputLable: {
    color: '#8A8A8F'
  },
  error: {
    color: theme.colors.danger,
    marginTop: 4,
    lineHeight: 22
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    borderBottomColor: '#8A8A8F',
    borderBottomWidth: 1,
    color: theme.colors.white,
    width: '90%'
  },
  title: {
    color: theme.colors.white,
    fontSize: 20,
    lineHeight: 26
  }
});
