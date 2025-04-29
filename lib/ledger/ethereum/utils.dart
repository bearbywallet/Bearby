/// Returns the BIP32 derivation path for the given account index
/// Path format: m/44'/60'/account'/0/0
String getWalletDerivationPath(int accountIndex) =>
    "44'/60'/$accountIndex'/0/0";

/// Splits a BIP32 path into integer components
/// Handles hardened paths (ending with ')
List<int> splitPath(String path) {
  List<int> result = [];
  List<String> components = path.split("/");

  for (var element in components) {
    if (element.isEmpty) continue; // Skip empty parts (first slash)

    int number = int.tryParse(element.replaceAll("'", "")) ?? 0;

    if (element.length > 1 && element[element.length - 1] == "'") {
      // For hardened paths, add 0x80000000
      number += 0x80000000;
    }

    result.add(number);
  }

  return result;
}

String bytesToHex(List<int> bytes, {bool include0x = false}) {
  final buffer = StringBuffer();
  if (include0x) {
    buffer.write('0x');
  }

  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }

  return buffer.toString();
}
