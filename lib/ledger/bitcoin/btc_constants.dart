import 'package:bearby/config/bip_purposes.dart';

/// Constants for the Ledger Bitcoin app v2.1.0+ (new protocol).
///
/// The BTC Ledger app uses a completely different protocol from ETH/TRON/ZIL:
/// - CLA = 0xE1 (not 0xE0)
/// - Interactive merkle-based protocol for handling large PSBTs
/// - Device requests data from the client via interrupt status codes
class BtcLedgerConstants {
  BtcLedgerConstants._();

  // --- Application CLA ---
  static const int cla = 0xE1;

  // --- Framework (for sending client responses back) ---
  static const int frameworkCla = 0xF8;
  static const int frameworkContinueIns = 0x01;

  // --- APDU Instruction Codes ---
  static const int insGetPubkey = 0x00;
  static const int insRegisterWallet = 0x02;
  static const int insGetWalletAddress = 0x03;
  static const int insSignPsbt = 0x04;
  static const int insGetMasterFingerprint = 0x05;
  static const int insSignMessage = 0x10;

  // --- Client Command Codes (received in 0xE000 interrupt responses) ---
  static const int ccYield = 0x10;
  static const int ccGetPreimage = 0x40;
  static const int ccGetMerkleLeafProof = 0x41;
  static const int ccGetMerkleLeafIndex = 0x42;
  static const int ccGetMoreElements = 0xA0;

  // --- Status Words ---
  static const int swOk = 0x9000;
  static const int swInterrupt = 0xE000;

  /// Map BIP purpose to Ledger wallet descriptor template.
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
