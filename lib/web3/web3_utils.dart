import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:zilpay/src/rust/api/token.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/connection.dart';
import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/web3/zilpay_legacy.dart';

class Web3Utils {
  static ConnectionInfo? isDomainConnected(
    String currentDomain,
    List<ConnectionInfo> connections,
  ) {
    for (final conn in connections) {
      final connDomain = conn.domain;
      if (currentDomain == connDomain ||
          (currentDomain.endsWith('.$connDomain') &&
              currentDomain.split('.').length ==
                  connDomain.split('.').length + 1)) {
        return conn;
      }
    }
    return null;
  }

  static List<String> filterByIndexes(
    List<String> addresses,
    Uint64List indexes,
  ) {
    return indexes
        .toList()
        .where((index) =>
            index >= BigInt.zero && index < BigInt.from(addresses.length))
        .map((index) => addresses[index.toInt()])
        .toList();
  }

  static Future<(String?, BigInt?, FTokenInfo?, String?)>
      fetchTokenMetaLegacyZilliqa({
    required dynamic data,
    required String contracAddr,
    required BigInt walletIndex,
  }) async {
    String? toAddress;
    BigInt? tokenAmount;
    FTokenInfo? tokenInfo;
    String? teg;

    try {
      if (data != null) {
        Map<String, dynamic> dataMap;

        if (data is String) {
          dataMap = jsonDecode(data) as Map<String, dynamic>;
        } else if (data is Map<String, dynamic>) {
          dataMap = data;
        } else {
          return (null, null, null, null);
        }

        teg = dataMap['_tag'];

        if (teg == 'Transfer' && dataMap['params'] is List) {
          List params = dataMap['params'];

          final typedParams = params
              .map((param) => ZilPayLegacyTransactionParam.fromJson(
                  param as Map<String, dynamic>))
              .toList();

          final toParam = typedParams.firstWhere(
            (param) => param.vname == 'to',
            orElse: () =>
                ZilPayLegacyTransactionParam(vname: '', type: '', value: ''),
          );
          if (toParam.value.isNotEmpty) {
            toAddress =
                await zilliqaLegacyBase16ToBech32(base16: toParam.value);
            contracAddr =
                await zilliqaLegacyBase16ToBech32(base16: contracAddr);
          }

          final amountParam = typedParams.firstWhere(
            (param) => param.vname == 'amount',
            orElse: () =>
                ZilPayLegacyTransactionParam(vname: '', type: '', value: ''),
          );
          if (amountParam.value.isNotEmpty) {
            tokenAmount = BigInt.parse(amountParam.value);
          }

          if (contracAddr.startsWith("zil1")) {
            try {
              tokenInfo = await fetchTokenMeta(
                addr: contracAddr,
                walletIndex: walletIndex,
              );
            } catch (e) {
              debugPrint("fetchTokenMeta error: $e");
            }
          }
        }
      }
    } catch (_) {}

    return (toAddress, tokenAmount, tokenInfo, teg);
  }
}
