import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

const _hexChars = '0123456789abcdef';

String bytesToHex(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(_hexChars[(byte & 0xF0) >> 4]);
    buffer.write(_hexChars[byte & 0x0F]);
  }
  return buffer.toString();
}

Uint8List hexToBytes(String hex) {
  final hexWithoutPrefix = hex.startsWith('0x') ? hex.substring(2) : hex;

  if (hexWithoutPrefix.length % 2 != 0) {
    throw ArgumentError('Odd-length hex string.');
  }

  final result = Uint8List(hexWithoutPrefix.length ~/ 2);

  for (int i = 0; i < result.length; i++) {
    final hexPart = hexWithoutPrefix.substring(i * 2, i * 2 + 2);
    result[i] = int.parse(hexPart, radix: 16);
  }

  return result;
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
