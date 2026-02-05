import 'dart:typed_data';

class CipherDefaults {
  static const int defaultCipherIndex = 2; // Quantum

  static Uint8List getCipherOrders(int index) {
    switch (index) {
      case 0:
        return Uint8List.fromList([0, 1]); // AES-256 + KUZNECHIK-GOST
      case 1:
        return Uint8List.fromList([1, 3]); // CYBER + KUZNECHIK-GOST
      case 2:
        return Uint8List.fromList([3, 2, 1]); // CYBER + KUZNECHIK + NTRUP1277
      default:
        return Uint8List.fromList([3, 2, 1]);
    }
  }
}
