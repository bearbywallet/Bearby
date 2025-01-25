import 'dart:convert';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:zilpay/src/rust/models/provider.dart';

extension ChainConverter on Chain {
  NetworkConfigInfo toNetworkConfigInfo() {
    return NetworkConfigInfo(
      testnet: testnet,
      shortName: shortName,
      name: name,
      chain: chain,
      rpc: rpc.map((uri) => uri.toString()).toList(),
      features: Uint16List.fromList(
          features.map((f) => int.parse(f.replaceAll('EIP', ''))).toList()),
      chainId: BigInt.from(chainId),
      slip44: slip44,
      chainHash: BigInt.from(chainId),
      ens: ens?.registry ?? '',
      explorers: explorers
          .map((e) => ExplorerInfo(
                name: e.name,
                url: e.url.toString(),
                icon: e.icon,
                standard: e.standard.hashCode,
              ))
          .toList(),
      fallbackEnabled: true,
    );
  }
}

class Chain {
  Chain({
    required this.name,
    required this.chain,
    required this.rpc,
    required this.features,
    required this.faucets,
    required this.nativeCurrency,
    required this.infoURL,
    required this.shortName,
    required this.chainId,
    required this.networkId,
    required this.slip44,
    required this.explorers,
    this.ens,
    this.testnet,
  });

  bool? testnet;
  final String name;
  final String chain;
  final List<Uri> rpc;
  final List<String> features;
  final List<Uri> faucets;
  final NativeCurrency nativeCurrency;
  final Uri infoURL;
  final String shortName;
  final int chainId;
  final int networkId;
  final int slip44;
  final Ens? ens;
  final List<Explorer> explorers;

  factory Chain.fromJson(Map<String, dynamic> json) {
    return Chain(
      name: json['name'] as String? ?? '',
      chain: json['chain'] as String? ?? '',
      rpc: (json['rpc'] as List<dynamic>?)
              ?.map((e) => Uri.parse(e as String))
              .toList(growable: false) ??
          [],
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(growable: false) ??
          [],
      faucets: (json['faucets'] as List<dynamic>?)
              ?.map((e) => Uri.parse(e as String))
              .toList(growable: false) ??
          [],
      nativeCurrency: NativeCurrency.fromJson(
        json['nativeCurrency'] as Map<String, dynamic>? ?? {},
      ),
      infoURL: Uri.parse(json['infoURL'] as String? ?? ''),
      shortName: json['shortName'] as String? ?? '',
      chainId: json['chainId'] as int? ?? 0,
      networkId: json['networkId'] as int? ?? 0,
      slip44: json['slip44'] as int? ?? 0,
      ens: json['ens'] != null
          ? Ens.fromJson(json['ens'] as Map<String, dynamic>)
          : null,
      explorers: (json['explorers'] as List<dynamic>?)
              ?.map((e) => Explorer.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          [],
    );
  }
}

class NativeCurrency {
  const NativeCurrency({
    required this.name,
    required this.symbol,
    required this.decimals,
  });

  final String name;
  final String symbol;
  final int decimals;

  factory NativeCurrency.fromJson(Map<String, dynamic> json) {
    return NativeCurrency(
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      decimals: json['decimals'] as int? ?? 18,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'symbol': symbol,
        'decimals': decimals,
      };
}

class Ens {
  const Ens({
    required this.registry,
  });

  final String registry;

  factory Ens.fromJson(Map<String, dynamic> json) {
    return Ens(
      registry: json['registry'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'registry': registry,
      };
}

class Explorer {
  const Explorer({
    required this.name,
    required this.url,
    this.icon,
    required this.standard,
  });

  final String name;
  final Uri url;
  final String? icon;
  final String standard;

  factory Explorer.fromJson(Map<String, dynamic> json) {
    return Explorer(
      name: json['name'] as String? ?? '',
      url: Uri.parse(json['url'] as String? ?? ''),
      icon: json['icon'] as String?,
      standard: json['standard'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url.toString(),
        if (icon != null) 'icon': icon,
        'standard': standard,
      };
}

class ChainService {
  static Future<Chain> loadChain(String jsonString) async {
    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return Chain.fromJson(jsonMap);
    } catch (e) {
      throw FormatException('Invalid chain JSON format: $e');
    }
  }

  static Future<List<Chain>> loadChains(String jsonString) async {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((dynamic json) => Chain.fromJson(json as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e) {
      throw FormatException('Invalid chains JSON format: $e');
    }
  }
}
