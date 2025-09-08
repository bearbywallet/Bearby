import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:zilpay/ledger/ethereum/resolution_types.dart';

class ERC20Service {
  static Future<String?> findERC20SignaturesInfo(
    LoadConfig loadConfig,
    int chainId,
  ) async {
    final cryptoassetsBaseURL = loadConfig.cryptoassetsBaseURL;
    if (cryptoassetsBaseURL == null) return null;

    final url = '$cryptoassetsBaseURL/evm/$chainId/erc20-signatures.json';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = response.body;
        if (data.isNotEmpty) {
          return data;
        }
      }

      print('Error: could not fetch from $url: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error: could not fetch from $url: $e');
      return null;
    }
  }

  static TokenInfo? byContractAddressAndChainId(
    String contract,
    int chainId,
    String? erc20SignaturesBlob,
  ) {
    if (erc20SignaturesBlob == null) return null;

    try {
      return _parseSignatureBlob(erc20SignaturesBlob)
          .byContractAndChainId(_asContractAddress(contract), chainId);
    } catch (e) {
      print('Error parsing ERC20 signatures blob: $e');
      return null;
    }
  }

  static String _asContractAddress(String addr) {
    final a = addr.toLowerCase();
    return a.startsWith('0x') ? a : '0x$a';
  }

  static _SignatureAPI _parseSignatureBlob(String erc20SignaturesBlob) {
    String base64String = erc20SignaturesBlob;

    if (base64String.startsWith('"')) {
      try {
        base64String = json.decode(erc20SignaturesBlob) as String;
      } catch (e) {
        base64String = erc20SignaturesBlob.replaceAll('"', '');
      }
    }

    final buf = base64.decode(base64String);
    final map = <String, TokenInfo>{};
    final entries = <TokenInfo>[];
    int i = 0;

    while (i < buf.length) {
      if (i + 4 > buf.length) break;
      final length = _readUint32BE(buf, i);
      i += 4;

      if (i + length > buf.length) {
        print(
            'Warning: Invalid length at position $i, expected $length bytes but only ${buf.length - i} available');
        break;
      }

      final item = buf.sublist(i, i + length);
      int j = 0;

      if (j >= item.length) break;
      final tickerLength = item[j];
      j += 1;

      if (j + tickerLength > item.length) break;
      final ticker = String.fromCharCodes(item.sublist(j, j + tickerLength));
      j += tickerLength;

      if (j + 20 > item.length) break;
      final contractAddress = _asContractAddress(
        item
            .sublist(j, j + 20)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(),
      );
      j += 20;

      if (j + 4 > item.length) break;
      final decimals = _readUint32BE(item, j);
      j += 4;

      if (j + 4 > item.length) break;
      final chainId = _readUint32BE(item, j);
      j += 4;

      final signature = item.sublist(j);

      final entry = TokenInfo(
        ticker: ticker,
        contractAddress: contractAddress,
        decimals: decimals,
        chainId: chainId,
        signature: signature,
        data: item,
      );

      entries.add(entry);
      map['$chainId:$contractAddress'] = entry;
      i += length;
    }

    print('Parsed ${entries.length} ERC20 token entries');
    return _SignatureAPI(map, entries);
  }

  static int _readUint32BE(Uint8List buffer, int offset) {
    if (offset + 4 > buffer.length) {
      throw RangeError(
          'Offset $offset is out of bounds for buffer of length ${buffer.length}');
    }
    return (buffer[offset] << 24) |
        (buffer[offset + 1] << 16) |
        (buffer[offset + 2] << 8) |
        buffer[offset + 3];
  }
}

class _SignatureAPI {
  final Map<String, TokenInfo> _map;
  final List<TokenInfo> _entries;

  _SignatureAPI(this._map, this._entries);

  List<TokenInfo> list() => _entries;

  TokenInfo? byContractAndChainId(String contractAddress, int chainId) {
    final key = '$chainId:$contractAddress';
    final result = _map[key];
    if (result != null) {
      print(
          'Found token info for $contractAddress on chain $chainId: ${result.ticker}');
    } else {
      print('No token info found for $contractAddress on chain $chainId');
      print('Available keys: ${_map.keys.take(5).join(", ")}...');
    }
    return result;
  }
}

class ERC20Selectors {
  static const String transfer = '0xa9059cbb';
  static const String transferFrom = '0x23b872dd';
  static const String approve = '0x095ea7b3';

  static const List<String> clearSignedSelectors = [
    transfer,
    transferFrom,
    approve,
  ];
}
