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
  Linking,
  TouchableOpacity,
  Dimensions,
  ViewStyle
} from 'react-native';
import Clipboard from '@react-native-community/clipboard';
import Modal from 'react-native-modal';
import Share from 'react-native-share';
import { useStore } from 'effector-react';
import { SvgXml } from 'react-native-svg';

import QRCode from 'react-native-qrcode-svg';
import { CustomButton } from 'app/components/custom-button';
import {
  ProfileSVG,
  ViewBlockIconSVG,
  ShareIconSVG
} from 'app/components/svg';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { keystore } from 'app/keystore';
import { trim } from 'app/filters';
import { viewAddress } from 'app/utils';
import { QrcodeType } from 'types';
import { ORDERS } from 'app/config';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  onTriggered: () => void;
};

const { width } = Dimensions.get('window');
export const ReceiveModal: React.FC<Prop> = ({
  style,
  visible,
  onTriggered
}) => {
  const accountState = useStore(keystore.account.store);
  const settings = useStore(keystore.settings.store);
  const netwrokState = useStore(keystore.network.store);

  const [qrcodeRef, setQrcodeRef] = React.useState<QrcodeType | null>(null);

  const selected = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    []
  );
  const btnTitle = React.useMemo(() => {
    const [mainnet] = Object.keys(netwrokState.config);

    if (netwrokState.selected === mainnet) {
      return i18n.t('buy');
    }

    return i18n.t('faucet');
  }, [netwrokState]);

  /**
   * Copy address.
   */
  const hanldeCopy = React.useCallback(() => {
    Clipboard.setString(selected[settings.addressFormat]);
  }, [selected, settings]);
  const hanldeViewAddress = React.useCallback(() => {
    const url = viewAddress(selected.bech32, netwrokState.selected);

    Linking.openURL(url);
  }, [selected, netwrokState]);
  /**
   * Open share qrcode image.
   */
  const handleShare = React.useCallback(() => {
    if (!qrcodeRef) {
      return null;
    }

    return qrcodeRef.toDataURL((url) => {
      const shareOptions = {
        url: `data:image/png;base64,${url}`,
        type: 'image/png',
        title: selected.bech32
      };
      Share.open(shareOptions)
        .then(res => null)
        .catch(err => null);
    });
  }, [qrcodeRef, selected]);
  const handleGetZil = React.useCallback(() => {
    const [mainnet] = Object.keys(netwrokState.config);

    if (netwrokState.selected === mainnet) {
      Linking.openURL(ORDERS.TRANSAK_URL);

      return null;
    }

    Linking.openURL(ORDERS.FAUCET);
  }, [netwrokState]);

  return (
    <Modal
      isVisible={visible}
      style={{
        justifyContent: 'flex-end',
        margin: 0,
        marginBottom: 1
      }}
      onBackdropPress={onTriggered}
    >
      <ModalWrapper style={style}>
        <ModalTitle onClose={onTriggered}>
          {i18n.t('receive')}
        </ModalTitle>
        <View style={styles.qrcodeWrapper}>
          <QRCode
            value={`zilliqa://${selected.bech32}`}
            size={width / 2}
            getRef={setQrcodeRef}
          />
        </View>
        <Text style={styles.accountName}>
          {selected.name}
        </Text>
        <Text style={styles.accountAddress}>
          {trim(selected[settings.addressFormat])}
        </Text>
        <View style={styles.linkWrapper}>
          <TouchableOpacity
            style={styles.linkItem}
            onPress={handleShare}
          >
            <SvgXml xml={ShareIconSVG}/>
            <Text style={styles.linkText}>
              {i18n.t('share')}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.linkItem}
            onPress={hanldeCopy}
          >
            <SvgXml xml={ProfileSVG}/>
            <Text style={styles.linkText}>
              {i18n.t('copy_address')}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.linkItem}
            onPress={hanldeViewAddress}
          >
            <SvgXml xml={ViewBlockIconSVG}/>
            <Text style={styles.linkText}>
              {i18n.t('view_block')}
            </Text>
          </TouchableOpacity>
        </View>
        <View style={styles.btnWrapper}>
          <CustomButton
            title={btnTitle}
            onPress={handleGetZil}
          />
        </View>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  qrcodeWrapper: {
    paddingVertical: 15,
    alignItems: 'center'
  },
  accountName: {
    textAlign: 'center',
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22,
    marginTop: 15
  },
  accountAddress: {
    textAlign: 'center',
    color: '#8A8A8F',
    fontSize: 13,
    lineHeight: 17,
    marginBottom: 15
  },
  btnWrapper: {
    paddingHorizontal: 15,
    marginBottom: 15
  },
  linkWrapper: {
    paddingVertical: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-evenly'
  },
  linkItem: {
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#2B2E33',
    padding: 15,
    borderRadius: 8,
    width: 80,
    height: 80
  },
  linkText: {
    color: theme.colors.white,
    fontSize: 10,
    lineHeight: 13,
    textAlign: 'center',
    marginTop: 5
  }
});
