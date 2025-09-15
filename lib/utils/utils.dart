import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

List<int> hexToBytes(String hex) => [
      for (int i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16)
    ];

String bytesToHex(List<int> bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
}

String decodePersonalSignMessage(String dataToSign) {
  try {
    if (dataToSign.startsWith('0x')) {
      final bytes = hexToBytes(dataToSign.substring(2));
      return String.fromCharCodes(bytes);
    }
    return dataToSign;
  } catch (e) {
    return dataToSign;
  }
}

bool isDomainConnected(String domain, List<dynamic> connections) {
  return connections.any((conn) => conn.domain == domain);
}

List<String> filterByIndexes(List<String> addresses, Uint64List indexes) {
  return [
    for (var i = 0; i < indexes.length; i++)
      if (i < addresses.length) addresses[indexes[i].toInt()]
  ];
}
