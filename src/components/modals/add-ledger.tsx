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
  Text,
  Dimensions,
  TouchableOpacity,
  View
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import Svg, { Path } from 'react-native-svg';
import Modal from 'react-native-modal';
import TransportBLE from '@ledgerhq/react-native-hw-transport-ble';

import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { CustomTextInput } from 'app/components/custom-text-input';

import ProfileSVG from 'app/assets/icons/profile.svg';

import { LedgerController } from 'app/lib/controller/connect/ledger';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { fonts } from 'app/styles';

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
    } catch {
      //
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
          <View style={[styles.incWrapper, {
            backgroundColor: colors['bg1']
          }]}>
            <TouchableOpacity
              style={styles.btn}
              onPress={() => hanldeChangeIndex(Math.abs(index - 1))}
            >
              <Svg
                width="36"
                height="2"
                viewBox="0 0 36 2"
                fill="none"
              >
                <Path
                  d="M0 1H36"
                  stroke={colors.text}
                  strokeWidth="2"
                />
              </Svg>
            </TouchableOpacity>
            <Text style={[styles.plusText, {
              color: colors.text
            }]}>
              {index}
            </Text>
            <TouchableOpacity
              style={styles.btn}
              onPress={() => hanldeChangeIndex(index + 1)}
            >
              <Svg
                width="36"
                height="36"
                viewBox="0 0 36 36"
                fill="none"
              >
                <Path
                  d="M0 17H36M19 0L19 36"
                  stroke={colors.text}
                  strokeWidth="2"
                />
              </Svg>
            </TouchableOpacity>
          </View>
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

const styles = StyleSheet.create({
  plusText: {
    fontSize: 50,
    fontFamily: fonts.Demi
  },
  btn: {
    minWidth: 50,
    minHeight: 50,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16
  },
  incWrapper: {
    flexDirection: 'row',
    borderRadius: 16,
    justifyContent: 'space-between',
    alignItems: 'center',
    margin: 16
  }
});
