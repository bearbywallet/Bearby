import 'package:zilpay/config/ftokens.dart';

String generateCryptoUrl({
  required String address,
  required String chain,
  String? token,
  String? amount,
}) {
  final buffer = StringBuffer('$chain:$address');

  if (token != null && token != zeroZIL && token != zeroEVM) {
    buffer.write('?token=$token');

    if (amount != null && amount.isNotEmpty && amount != "0") {
      buffer.write('&amount=$amount');
    }
  } else if (amount != null && amount.isNotEmpty && amount != "0") {
    buffer.write('?amount=$amount');
  }

  return buffer.toString();
}

String generateQRSecretData({
  required String chain,
  String? seedPhrase,
  String? privateKey,
}) {
  final params = <String>[];

  if (seedPhrase != null) {
    params.add('seed=$seedPhrase');
  }

  if (privateKey != null) {
    params.add('key=$privateKey');
  }

  return '$chain:?${params.join('&')}';
}

Map<String, String> parseQRSecretData(String qrData) {
  final result = <String, String>{};

  final parts = qrData.split(':?');
  if (parts.length != 2) return result;

  result['chain'] = parts[0];

  final params = parts[1].split('&');
  for (final param in params) {
    final keyValue = param.split('=');
    if (keyValue.length == 2) {
      if (keyValue[0] == 'seed') result['seed'] = keyValue[1];
      if (keyValue[0] == 'key') result['key'] = keyValue[1];
    }
  }

  return result;
}
