// import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/src/rust/models/provider.dart';

class PostQuantumChains {
  static const Set<int> slip44s = <int>{
    // kBitcoinlip44,
  };

  static bool contains(NetworkConfigInfo chain) =>
      slip44s.contains(chain.slip44);
}
