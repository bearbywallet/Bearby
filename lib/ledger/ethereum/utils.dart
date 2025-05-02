String getWalletDerivationPath(int accountIndex) {
  if (accountIndex < 0) {
    throw ArgumentError('accountIndex должен быть >= 0');
  }
  return "m/44'/60'/0'/0/$accountIndex";
}

List<int> splitPath(String path) {
  List<int> result = [];
  List<String> components = path.split("/");

  for (var element in components) {
    if (element.isEmpty || element == "m") continue;

    int number = int.tryParse(element.replaceAll("'", "")) ?? 0;

    if (element.length > 1 && element[element.length - 1] == "'") {
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
