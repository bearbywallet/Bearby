import 'package:bearby/config/bip_purposes.dart';

class BtcLedgerConstants {
  BtcLedgerConstants._();

  static const int cla = 0xE1;

  static const int frameworkCla = 0xF8;
  static const int frameworkContinueIns = 0x01;

  static const int insGetPubkey = 0x00;
  static const int insRegisterWallet = 0x02;
  static const int insGetWalletAddress = 0x03;
  static const int insSignPsbt = 0x04;
  static const int insGetMasterFingerprint = 0x05;
  static const int insSignMessage = 0x10;

  static const int ccYield = 0x10;
  static const int ccGetPreimage = 0x40;
  static const int ccGetMerkleLeafProof = 0x41;
  static const int ccGetMerkleLeafIndex = 0x42;
  static const int ccGetMoreElements = 0xA0;

  static const int swOk = 0x9000;
  static const int swInterrupt = 0xE000;

  static String? descriptorTemplateForBip(int bip) {
    switch (bip) {
      case kBip44Purpose:
        return 'pkh(@0)';
      case kBip49Purpose:
        return 'sh(wpkh(@0))';
      case kBip84Purpose:
        return 'wpkh(@0)';
      case kBip86Purpose:
        return 'tr(@0)';
      default:
        return null;
    }
  }
}
