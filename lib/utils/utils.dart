import 'dart:io';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:zilpay/src/rust/models/keypair.dart';

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
      if (indexes[i] >= BigInt.zero && indexes[i].toInt() < addresses.length)
        addresses[indexes[i].toInt()]
  ];
}

extension SecureListExtension on List<String> {
  void zeroize() {
    for (var i = 0; i < length; i++) {
      this[i] = '';
    }
    clear();
  }
}

extension SecureKeyPairExtension on KeyPairInfo {
  KeyPairInfo zeroize() {
    return KeyPairInfo(sk: "", pk: "");
  }
}

String detectDeviceCurrency() {
  final locale = Platform.localeName;
  final langCode = locale.split('_').first.toLowerCase();
  final countryCode =
      locale.split('_').length > 1 ? locale.split('_')[1].toUpperCase() : '';

  final countryCurrencyMap = {
    'US': 'USD',
    'GB': 'GBP',
    'CA': 'CAD',
    'AU': 'AUD',
    'NZ': 'NZD',
    'JP': 'JPY',
    'CN': 'CNY',
    'KR': 'KRW',
    'RU': 'RUB',
    'TR': 'TRY',
    'IN': 'INR',
    'TH': 'THB',
    'VN': 'VND',
    'ID': 'IDR',
    'MY': 'MYR',
    'SE': 'SEK',
    'NO': 'NOK',
    'DK': 'DKK',
    'CZ': 'CZK',
    'HU': 'HUF',
    'RO': 'RON',
    'BG': 'BGN',
    'UA': 'UAH',
    'IL': 'ILS',
    'BR': 'BRL',
    'MX': 'MXN',
    'AR': 'ARS',
    'SG': 'SGD',
    'HK': 'HKD',
    'ZA': 'ZAR',
    'CH': 'CHF',
    'IE': 'EUR',
    'DE': 'EUR',
    'FR': 'EUR',
    'ES': 'EUR',
    'IT': 'EUR',
    'PT': 'EUR',
    'NL': 'EUR',
    'PL': 'EUR',
    'FI': 'EUR',
    'HR': 'EUR',
    'SK': 'EUR',
    'SI': 'EUR',
    'LT': 'EUR',
    'LV': 'EUR',
    'EE': 'EUR',
    'GR': 'EUR',
    'AT': 'EUR',
    'BE': 'EUR',
    'CY': 'EUR',
    'LU': 'EUR',
    'MT': 'EUR',
  };

  if (countryCurrencyMap.containsKey(countryCode)) {
    return countryCurrencyMap[countryCode]!;
  }

  final langCurrencyMap = {
    'de': 'EUR',
    'fr': 'EUR',
    'es': 'EUR',
    'it': 'EUR',
    'pt': 'EUR',
    'nl': 'EUR',
    'pl': 'EUR',
    'ja': 'JPY',
    'zh': 'CNY',
    'ko': 'KRW',
    'ru': 'RUB',
    'tr': 'TRY',
    'ar': 'USD',
    'hi': 'INR',
    'th': 'THB',
    'vi': 'VND',
    'id': 'IDR',
    'ms': 'MYR',
    'sv': 'SEK',
    'no': 'NOK',
    'da': 'DKK',
    'fi': 'EUR',
    'cs': 'CZK',
    'hu': 'HUF',
    'ro': 'RON',
    'bg': 'BGN',
    'hr': 'EUR',
    'sk': 'EUR',
    'sl': 'EUR',
    'lt': 'EUR',
    'lv': 'EUR',
    'et': 'EUR',
    'uk': 'UAH',
    'he': 'ILS',
    'el': 'EUR',
  };

  if (langCurrencyMap.containsKey(langCode)) {
    return langCurrencyMap[langCode]!;
  }

  return 'USD';
}
