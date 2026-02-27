import 'package:bearby/config/ftokens.dart';

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

Map<String, String?> parseCryptoUrl(String url) {
  final result = <String, String?>{};

  final colonIndex = url.indexOf(':');
  if (colonIndex == -1) return result;

  result['chain'] = url.substring(0, colonIndex);

  final afterColon = url.substring(colonIndex + 1);
  final questionIndex = afterColon.indexOf('?');

  if (questionIndex == -1) {
    result['address'] = afterColon;
    return result;
  }

  result['address'] = afterColon.substring(0, questionIndex);

  final queryString = afterColon.substring(questionIndex + 1);
  final params = queryString.split('&');

  for (final param in params) {
    final keyValue = param.split('=');
    if (keyValue.length == 2) {
      result[keyValue[0]] = keyValue[1];
    }
  }

  return result;
}
