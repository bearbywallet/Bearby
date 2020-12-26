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
import Modal from 'react-native-modal';

import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title: string;
  btnTitle: string;
  onTriggered: () => void;
  onConfirmed: (passowrd: string) => void;
};

/**
 * Modal wiht password validator.
 * @example
 * import { PasswordModal } from 'app/components/modals';
 * const [modalVisible, setModalVisible] = React.useState(true);
 *
 * <PasswordModal
 *   visible={modalVisible}
 *   title="test title of modal"
 *   btnTitle="submit"
 *   onTriggered={() => setModalVisible(false)}
 *   onConfirmed={hanldeConfirmPassword}
 * />
 */
export const PasswordModal: React.FC<Prop> = ({
  style,
  visible,
  title,
  btnTitle,
  onTriggered,
  onConfirmed
}) => {
  const { colors, dark } = useTheme();
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
        margin: 0,
        marginBottom: 1
      }}
      backdropColor={dark ? '#ffffff5' : '#00000060'}
      onBackdropPress={onTriggered}
    >
      <ModalWrapper style={style}>
        <ModalTitle onClose={onTriggered}>
          {title}
        </ModalTitle>
        <View>
          <TextInput
            style={[styles.textInput, {
              color: colors.text,
              borderBottomColor: colors.border,
            }]}
            secureTextEntry={true}
            placeholder={i18n.t('pass_setup_input1')}
            placeholderTextColor={colors.border}
            onSubmitEditing={hanldeConfirm}
            onChangeText={hanldeChangePassword}
          />
          <Text style={[styles.error, {
            color: colors['danger']
          }]}>
            {errorMessage}
          </Text>
        </View>
        <CustomButton
          title={btnTitle}
          onPress={hanldeConfirm}
        />
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  error: {
    marginTop: 4,
    lineHeight: 22
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    borderBottomWidth: 1,
    width: '90%'
  }
});
