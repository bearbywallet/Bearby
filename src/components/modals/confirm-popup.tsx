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
  ScrollView,
  Text,
  ViewStyle,
  View
} from 'react-native';
import { SvgXml, SvgCssUri } from 'react-native-svg';

import {
  ProfileSVG,
  ReceiveIconSVG,
  AmountIconSVG
} from 'app/components/svg';
import commonStyles from 'app/components/transfer/styles';
import { AdvacedGas } from 'app/components/advaced-gas';
import Modal from 'react-native-modal';
import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';

import { Token, Account } from 'types';
import { TOKEN_ICONS } from 'app/config';
import i18n from 'app/lib/i18n';
import { fromZil, toConversion, trim, toLocaleString } from 'app/filters';
import { keystore } from 'app/keystore';
import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  token: Token;
  account: Account;
  title: string;
  amount: string;
  netwrok: string;
  recipient: string;
  onTriggered: () => void;
};

export const ConfirmPopup: React.FC<Prop> = ({
  title,
  style,
  token,
  account,
  netwrok,
  amount,
  visible,
  recipient,
  onTriggered
}) => {
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();
  const gasState = keystore.gas.store.useValue();

  const [DS, setDS] = React.useState(false);
  const [gas, setGas] = React.useState(gasState);

  const conversion = React.useMemo(() => {
    const rate = settingsState.rate[currencyState];
    const balance = account.balance[netwrok][token.symbol];
    const value = toConversion(balance, rate, token.decimals);

    return toLocaleString(value);
  }, [token, account, netwrok, settingsState, currencyState]);

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
        <ModalTitle
          style={{ padding: 15 }}
          onClose={onTriggered}
        >
          <View style={styles.topWrapper}>
            <SvgCssUri
              height="30"
              width="30"
              uri={`${TOKEN_ICONS}/${token.symbol}.svg`}
            />
            <Text style={styles.toptext}>
              {title}
            </Text>
          </View>
        </ModalTitle>
        <ScrollView style={{ marginBottom: 15 }}>
          <View style={commonStyles.item}>
            <SvgXml xml={ProfileSVG} />
            <View style={[commonStyles.itemInfo, styles.item]}>
              <Text style={commonStyles.label}>
                {i18n.t('transfer_account')}
              </Text>
              <View style={commonStyles.infoWrapper}>
                <Text style={commonStyles.nameAmountText}>
                  {account.name}
                </Text>
                <Text style={commonStyles.addressAmount}>
                  {trim(account[settingsState.addressFormat])}
                </Text>
              </View>
            </View>
          </View>
          <View style={commonStyles.item}>
            <SvgXml xml={AmountIconSVG} />
            <View style={[commonStyles.itemInfo, styles.item]}>
              <Text style={commonStyles.label}>
                {i18n.t('transfer_amount')}
              </Text>
              <View style={commonStyles.infoWrapper}>
                <Text style={commonStyles.nameAmountText}>
                  {toLocaleString(fromZil(amount, token.decimals))}
                </Text>
                <Text style={commonStyles.addressAmount}>
                  {conversion} {currencyState}
                </Text>
              </View>
            </View>
          </View>
          <View style={commonStyles.item}>
            <SvgXml xml={ReceiveIconSVG} />
            <View style={[commonStyles.itemInfo, styles.item]}>
              <Text style={commonStyles.label}>
                {i18n.t('recipient_account')}
              </Text>
              <View style={commonStyles.infoWrapper}>
                <Text style={commonStyles.nameAmountText}>
                  {trim(recipient)}
                </Text>
              </View>
            </View>
          </View>
          <AdvacedGas
            gas={gas}
            ds={DS}
            onDSChanged={setDS}
            onChange={setGas}
          />
          <CustomButton
            title={i18n.t('send')}
            style={styles.sendBtn}
            onPress={() => null}
          />
        </ScrollView>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  item: {
    paddingBottom: 10
  },
  sendBtn: {
    marginVertical: 15
  },
  topWrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  toptext: {
    paddingLeft: 5,
    fontSize: 20,
    lineHeight: 26,
    fontWeight: 'bold',
    color: theme.colors.white
  }
});
