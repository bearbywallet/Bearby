import 'package:bearby/config/web3_constants.dart';

String defaultDerivePath({required int bipPurpose, required int slip44}) {
  if (slip44 == kSolanaSlip44) {
    return "m/$bipPurpose'/$slip44'/0'/0'";
  }
  return "m/$bipPurpose'/$slip44'/0'/0/0";
}
