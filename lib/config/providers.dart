import 'dart:convert';

String chainNameBySymbol(String symbol) {
  return "ethereum";
}

String? symbolByChainName(String name) {
  return "ETH";
}

bool isMainnetNetwork(BigInt chainId) {
  final mainnetChainIds = [
    BigInt.from(1), // Ethereum Mainnet
    BigInt.from(56), // BNB Smart Chain Mainnet
    BigInt.from(32770) // Zilliqa Mainnet
  ];

  return mainnetChainIds.contains(chainId);
}

class Chain {
  const Chain({
    required this.name,
    required this.chain,
    required this.icon,
    required this.rpc,
    required this.features,
    required this.faucets,
    required this.nativeCurrency,
    required this.infoURL,
    required this.shortName,
    required this.chainId,
    required this.networkId,
    required this.slip44,
    this.ens,
    required this.explorers,
  });

  final String name;
  final String chain;
  final String icon;
  final List<Uri> rpc;
  final List<Feature> features;
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
      icon: json['icon'] as String? ?? '',
      rpc: (json['rpc'] as List<dynamic>?)
              ?.map((e) => Uri.parse(e as String))
              .toList(growable: false) ??
          [],
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => Feature.fromJson(e as Map<String, dynamic>))
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'chain': chain,
        'icon': icon,
        'rpc': rpc.map((uri) => uri.toString()).toList(growable: false),
        'features': features.map((f) => f.toJson()).toList(growable: false),
        'faucets': faucets.map((uri) => uri.toString()).toList(growable: false),
        'nativeCurrency': nativeCurrency.toJson(),
        'infoURL': infoURL.toString(),
        'shortName': shortName,
        'chainId': chainId,
        'networkId': networkId,
        'slip44': slip44,
        if (ens != null) 'ens': ens!.toJson(),
        'explorers': explorers.map((e) => e.toJson()).toList(growable: false),
      };
}

class Feature {
  const Feature({
    required this.name,
  });

  final String name;

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
      };
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
