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
  Dimensions,
  ViewStyle
} from 'react-native';
import Clipboard from '@react-native-community/clipboard';
import Modal from 'react-native-modal';
import Share from 'react-native-share';
import { useTheme } from '@react-navigation/native';

import QRCode from 'react-native-qrcode-svg';
import { CustomButton } from 'app/components/custom-button';
import {
  ProfileSVG,
  ViewBlockIconSVG,
  ShareIconSVG
} from 'app/components/svg';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { ViewButton } from 'app/components/view-button';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { trim } from 'app/filters';
import { viewAddress } from 'app/utils';
import { QrcodeType, Account } from 'types';
import { ORDERS } from 'app/config';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  account: Account;
  onTriggered: () => void;
  onViewblock: (url: string) => void;
};

const { width } = Dimensions.get('window');
export const ReceiveModal: React.FC<Prop> = ({
  style,
  visible,
  account,
  onTriggered,
  onViewblock
}) => {
  const { colors } = useTheme();
  const settingsState = keystore.settings.store.useValue();
  const networkState = keystore.network.store.useValue();

  const [qrcodeRef, setQrcodeRef] = React.useState<QrcodeType | null>(null);

  const btnTitle = React.useMemo(() => {
    const [mainnet] = Object.keys(networkState.config);

    if (networkState.selected === mainnet) {
      return i18n.t('buy');
    }

    return i18n.t('faucet');
  }, [networkState]);

  /**
   * Copy address.
   */
  const hanldeCopy = React.useCallback(() => {
    Clipboard.setString(account[settingsState.addressFormat]);
  }, [account, settingsState]);
  const hanldeViewAddress = React.useCallback(() => {
    const url = viewAddress(account.bech32, networkState.selected);

    onViewblock(url);
  }, [account, networkState]);
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
        title: account.bech32
      };
      Share.open(shareOptions)
        .then(res => null)
        .catch(err => null);
    });
  }, [qrcodeRef, account]);
  const handleGetZil = React.useCallback(() => {
    const [mainnet] = Object.keys(networkState.config);

    if (networkState.selected === mainnet) {
      onViewblock(ORDERS.TRANSAK_URL);

      return null;
    }

    onViewblock(ORDERS.FAUCET);
  }, [networkState]);

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
      <ModalWrapper style={style}>
        <ModalTitle onClose={onTriggered}>
          {i18n.t('receive')}
        </ModalTitle>
        <View style={styles.qrcodeWrapper}>
          <QRCode
            value={`zilliqa://${account.bech32}`}
            size={width / 2}
            backgroundColor={colors['black']}
            color={colors['white']}
            getRef={setQrcodeRef}
          />
        </View>
        <Text style={[styles.accountName, {
          color: colors.text
        }]}>
          {account.name}
        </Text>
        <Text style={[styles.accountAddress, {
          color: colors.border
        }]}>
          {trim(account[settingsState.addressFormat])}
        </Text>
        <View style={styles.linkWrapper}>
          <ViewButton
            icon={ShareIconSVG}
            onPress={handleShare}
          >
            {i18n.t('share')}
          </ViewButton>
          <ViewButton
            icon={ProfileSVG}
            onPress={hanldeCopy}
          >
            {i18n.t('copy_address')}
          </ViewButton>
          <ViewButton
            icon={ViewBlockIconSVG}
            onPress={hanldeViewAddress}
          >
            {i18n.t('view_block')}
          </ViewButton>
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
    fontSize: 17,
    fontFamily: fonts.Demi,
    marginTop: 15
  },
  accountAddress: {
    textAlign: 'center',
    fontSize: 13,
    fontFamily: fonts.Regular,
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
  }
});
