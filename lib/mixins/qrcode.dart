import 'package:bearby/config/ftokens.dart';

enum QrSecretKind { bearby, bip39Mnemonic, wifPrivateKey, hexPrivateKey, unknown }

class QrSecretResult {
  final QrSecretKind kind;

  /// Normalized payload:
  /// - bearby        → null; caller uses parseQRSecretData on the original string
  /// - bip39Mnemonic → single-space joined, trimmed mnemonic string
  /// - wifPrivateKey → raw WIF string (trimmed)
  /// - hexPrivateKey → lowercase 64-char hex WITHOUT 0x prefix
  /// - unknown       → null
  final String? payload;

  /// Only set for [QrSecretKind.bearby]: the chain prefix (e.g. "ETH", "ZIL").
  final String? chain;

  const QrSecretResult({required this.kind, this.payload, this.chain});
}

final _wifCompressedRegex = RegExp(r'^[KL][1-9A-HJ-NP-Za-km-z]{51}$');
final _wifUncompressedRegex = RegExp(r'^5[1-9A-HJ-NP-Za-km-z]{50}$');
final _hexKeyRegex = RegExp(r'^(?:0[xX])?([0-9a-fA-F]{64})$');
final _bip39WordRegex = RegExp(r'^[a-z]+$');

/// Detects and parses any supported QR secret format:
/// - Bearby format (`chain:?seed=...` / `chain:?key=...`)
/// - Plain BIP39 mnemonic (12/15/18/21/24 lowercase words)
/// - Bitcoin WIF private key (K.../L... 52 chars or 5... 51 chars)
/// - Plain hex private key (64 hex chars, optional 0x prefix)
QrSecretResult parseAnyQrSecret(String qrData) {
  final trimmed = qrData.trim();
  if (trimmed.isEmpty) return const QrSecretResult(kind: QrSecretKind.unknown);

  // 1. Bearby format: chain:?seed=... or chain:?key=...
  if (trimmed.contains(':?')) {
    final parsed = parseQRSecretData(trimmed);
    if (parsed.containsKey('chain')) {
      return QrSecretResult(
        kind: QrSecretKind.bearby,
        chain: parsed['chain'],
      );
    }
  }

  // 2. Plain BIP39 mnemonic: space-separated lowercase alpha words, valid count
  final words =
      trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  const validWordCounts = {12, 15, 18, 21, 24};
  if (validWordCounts.contains(words.length) &&
      words.every((w) => _bip39WordRegex.hasMatch(w))) {
    return QrSecretResult(
      kind: QrSecretKind.bip39Mnemonic,
      payload: words.join(' '),
    );
  }

  // 3. Bitcoin WIF key
  if (_wifCompressedRegex.hasMatch(trimmed) ||
      _wifUncompressedRegex.hasMatch(trimmed)) {
    return QrSecretResult(kind: QrSecretKind.wifPrivateKey, payload: trimmed);
  }

  // 4. Plain hex private key (64 hex chars, optional 0x prefix)
  final hexMatch = _hexKeyRegex.firstMatch(trimmed);
  if (hexMatch != null) {
    return QrSecretResult(
      kind: QrSecretKind.hexPrivateKey,
      payload: hexMatch.group(1)!.toLowerCase(),
    );
  }

  return const QrSecretResult(kind: QrSecretKind.unknown);
}

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
