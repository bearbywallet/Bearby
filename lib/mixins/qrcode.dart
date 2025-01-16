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
