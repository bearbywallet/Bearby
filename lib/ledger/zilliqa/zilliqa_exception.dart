import 'package:bearby/ledger/transport/exceptions.dart';

// SW_OK                0x9000
const int ok = 0x9000;

// SW_USER_REJECTED     0x6985
const int userRejected = 0x6985;

// SW_USER_REJECTED     8
const int userPubKeyRejected = 8;

// SW_WRONG_DATA_LENGTH 0x6A87
const int wrongDataLength = 0x6A87;

// SW_INS_NOT_SUPPORTED 0x6D00
const int insNotSupported = 0x6D00;

// SW_CLA_NOT_SUPPORTED 0x6E00
const int claNotSupported = 0x6E00;

// SW_DEVELOPER_ERR     0x6B00
const int developerError = 0x6B00;

// SW_INVALID_PARAM     0x6B01
const int invalidParam = 0x6B01;

// SW_IMPROPER_INIT     0x6B02
const int improperInit = 0x6B02;

TransportStatusError? checkZilliqaSW(int sw) {
  switch (sw) {
    case userRejected:
      return TransportStatusError(
          sw, 'User rejected the operation on the device.');
    case userPubKeyRejected:
      return TransportStatusError(sw, 'User rejected key reveal.');
    case wrongDataLength:
      return TransportStatusError(sw, 'Incorrect data length received.');
    case insNotSupported:
      return TransportStatusError(
          sw, 'Instruction (INS) not supported by the app.');
    case claNotSupported:
      return TransportStatusError(sw, 'Instruction class (CLA) not supported.');
    case developerError:
      return TransportStatusError(sw, 'Wrong parameters (P1-P2).');
    case invalidParam:
      return TransportStatusError(sw, 'An invalid parameter was provided.');
    case improperInit:
      return TransportStatusError(sw, 'Improper initialization or app state.');
    default:
      return null;
  }
}
