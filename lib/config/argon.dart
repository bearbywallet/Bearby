import 'package:bearby/src/rust/models/settings.dart';

class Argon2DefaultParams {
  static WalletArgonParamsInfo owaspDefault({String secret = ''}) {
    return WalletArgonParamsInfo(
      secret: secret,
      memory: 6553,
      iterations: 2,
      threads: 1,
    );
  }

  static WalletArgonParamsInfo lowMemory({String secret = ''}) {
    return WalletArgonParamsInfo(
      memory: 64 * 1024,
      iterations: 3,
      threads: 1,
      secret: secret,
    );
  }

  static WalletArgonParamsInfo secure({String secret = ''}) {
    return WalletArgonParamsInfo(
      memory: 256 * 1024,
      iterations: 4,
      threads: 4,
      secret: secret,
    );
  }
}
