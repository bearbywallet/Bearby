import 'package:bearby/config/web3_constants.dart';

enum DerivePathType {
  root,
  account,
  accountChange,
  addressIndex,
}

DerivePathType defaultDerivePathType(int slip44) {
  if (slip44 == kSolanaSlip44) return DerivePathType.accountChange;
  return DerivePathType.addressIndex;
}

List<DerivePathType> supportedDerivePathTypes(int slip44) {
  if (slip44 == kSolanaSlip44) {
    return [DerivePathType.root, DerivePathType.account, DerivePathType.accountChange];
  }
  return DerivePathType.values;
}

String buildDerivePath({
  required DerivePathType type,
  required int bipPurpose,
  required int slip44,
  int account = 0,
  int change = 0,
  int index = 0,
}) {
  switch (type) {
    case DerivePathType.root:
      return "m/$bipPurpose'/$slip44'";
    case DerivePathType.account:
      return "m/$bipPurpose'/$slip44'/$account'";
    case DerivePathType.accountChange:
      return "m/$bipPurpose'/$slip44'/$account'/$change'";
    case DerivePathType.addressIndex:
      return "m/$bipPurpose'/$slip44'/$account'/$change/$index";
  }
}
