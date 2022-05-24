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
  Dimensions,
  View,
  Alert
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import Modal from 'react-native-modal';
import TransportBLE from '@ledgerhq/react-native-hw-transport-ble';

import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { CustomTextInput } from 'app/components/custom-text-input';
import { Indexer } from 'app/components/indexer';

import ProfileSVG from 'app/assets/icons/profile.svg';

import { LedgerController } from 'app/lib/controller/connect/ledger';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';

type Prop = {
  visible: boolean;
  title: string;
  btnTitle: string;
  mac: string;
  onTriggered: () => void;
  onConfirmed: () => void;
};

const { width } = Dimensions.get('window');
export const LedgerAddModal: React.FC<Prop> = ({
  visible,
  title,
  btnTitle,
  onTriggered,
  mac,
  onConfirmed
}) => {
  const { colors } = useTheme();
  const [loading, setLoading] = React.useState(false);
  const [index, setIndex] = React.useState(0);
  const [isChangedName, setIsChangedName] = React.useState(false);
  const [name, setName] = React.useState(i18n.t('acc_name_ledger', {
    index
  }));

  const hanldeChangeName = React.useCallback((newName: string) => {
    setName(newName);
    setIsChangedName(true);
  }, []);
  const hanldeChangeIndex = React.useCallback((newIndex: number) => {
    setIndex(newIndex);

    if (!isChangedName) {
      setName(i18n.t('acc_name_ledger', {
        index: newIndex
      }));
    }
  }, [index, isChangedName]);

  const hanldeOpenDevice = React.useCallback(async() => {
    setLoading(true);
    try {
      const transport = await TransportBLE.open(mac);
      const ledger = new LedgerController(transport);
      const account = await ledger.getPublicAddress(index);

      await keystore.addLedgerAccount(
        name,
        account.publicKey,
        index,
        mac
      );
      onConfirmed();
    } catch (err) {
      Alert.alert(
        'Ledger connect',
        (err as Error).message,
        [
          { text: "OK" }
        ]
      );
    }
    setLoading(false);
  }, [mac, index, name]);

  return (
    <Modal
      isVisible={visible}
      style={{
        justifyContent: 'flex-end',
        margin: 0,
        marginBottom: 1
      }}
      backdropColor={colors['modal']}
      onBackdropPress={onTriggered}
    >
      <ModalWrapper>
        <ModalTitle onClose={onTriggered}>
          {title}
        </ModalTitle>
        <View>
          <CustomTextInput
            style={{
              marginVertical: 16
            }}
            defaultValue={name}
            Icon={ProfileSVG}
            maxWidth={width - 100}
            labelText={i18n.t('pass_setup_label0')}
            placeholder={i18n.t('pass_setup_input0')}
            onChangeText={hanldeChangeName}
          />
          <Indexer
            value={index}
            onChange={hanldeChangeIndex}
          />
        </View>
        <CustomButton
          title={btnTitle}
          isLoading={loading}
          onPress={hanldeOpenDevice}
        />
      </ModalWrapper>
    </Modal>
  );
};
