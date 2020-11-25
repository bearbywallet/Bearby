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
  Text,
  TouchableOpacity,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import {
  ArrowIconSVG,
  ReceiveIconSVG
} from 'app/components/svg';

import i18n from 'app/lib/i18n';
import styles from './styles';

type Prop = {
  style?: ViewStyle;
  onSelect: (index: number) => void;
};

export const TransferRecipient: React.FC<Prop> = ({
  style,
  onSelect
}) => {
  const [recipientModal, setRecipientModal] = React.useState(false);

  return (
    <React.Fragment>
      <TouchableOpacity style={[styles.receiving, style]}>
        <SvgXml xml={ReceiveIconSVG} />
        <Text style={styles.receivinglabel}>
          {i18n.t('transfer_view0')}
        </Text>
        <SvgXml
          xml={ArrowIconSVG}
          fill="#666666"
          style={styles.arrowIcon}
        />
      </TouchableOpacity>
    </React.Fragment>
  );
};
