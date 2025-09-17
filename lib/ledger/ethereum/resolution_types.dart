import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class LedgerEthTransactionResolution {
  final List<String> erc20Tokens;
  final List<String> nfts;
  final List<ExternalPlugin> externalPlugin;
  final List<String> plugin;
  final List<DomainDescriptor> domains;

  const LedgerEthTransactionResolution({
    this.erc20Tokens = const [],
    this.nfts = const [],
    this.externalPlugin = const [],
    this.plugin = const [],
    this.domains = const [],
  });

  LedgerEthTransactionResolution copyWith({
    List<String>? erc20Tokens,
    List<String>? nfts,
    List<ExternalPlugin>? externalPlugin,
    List<String>? plugin,
    List<DomainDescriptor>? domains,
  }) {
    return LedgerEthTransactionResolution(
      erc20Tokens: erc20Tokens ?? this.erc20Tokens,
      nfts: nfts ?? this.nfts,
      externalPlugin: externalPlugin ?? this.externalPlugin,
      plugin: plugin ?? this.plugin,
      domains: domains ?? this.domains,
    );
  }

  static LedgerEthTransactionResolution merge(
      List<LedgerEthTransactionResolution> resolutions) {
    return resolutions.fold(
      const LedgerEthTransactionResolution(),
      (merged, resolution) => LedgerEthTransactionResolution(
        erc20Tokens: [...merged.erc20Tokens, ...resolution.erc20Tokens],
        nfts: [...merged.nfts, ...resolution.nfts],
        externalPlugin: [
          ...merged.externalPlugin,
          ...resolution.externalPlugin
        ],
        plugin: [...merged.plugin, ...resolution.plugin],
        domains: [...merged.domains, ...resolution.domains],
      ),
    );
  }
}

class ExternalPlugin {
  final String payload;
  final String signature;

  const ExternalPlugin({
    required this.payload,
    required this.signature,
  });
}

class DomainDescriptor {
  final String domain;
  final String address;
  final String registry;
  final String type;

  const DomainDescriptor({
    required this.domain,
    required this.address,
    required this.registry,
    required this.type,
  });
}

class ResolutionConfig {
  final bool nft;
  final bool externalPlugins;
  final bool erc20;
  final List<DomainDescriptor> domains;
  final bool uniswapV3;

  const ResolutionConfig({
    this.nft = false,
    this.externalPlugins = false,
    this.erc20 = false,
    this.domains = const [],
    this.uniswapV3 = false,
  });
}

class LoadConfig {
  final String? nftExplorerBaseURL;
  final String? pluginBaseURL;
  final Map<String, dynamic>? extraPlugins;
  final String? cryptoassetsBaseURL;
  final String? calServiceURL;

  const LoadConfig({
    this.nftExplorerBaseURL = 'https://nft.api.live.ledger.com/v1/ethereum',
    this.pluginBaseURL = 'https://cdn.live.ledger.com',
    this.extraPlugins,
    this.cryptoassetsBaseURL = 'https://cdn.live.ledger.com/cryptoassets',
    this.calServiceURL = 'https://crypto-assets-service.api.ledger.com',
  });
}

class TokenInfo {
  final String contractAddress;
  final String ticker;
  final int decimals;
  final int chainId;
  final Uint8List signature;
  final Uint8List data;

  const TokenInfo({
    required this.contractAddress,
    required this.ticker,
    required this.decimals,
    required this.chainId,
    required this.signature,
    required this.data,
  });
}

class ContractMethod {
  final String payload;
  final String signature;
  final String plugin;
  final List<String> erc20OfInterest;
  final Map<String, dynamic> abi;

  const ContractMethod({
    required this.payload,
    required this.signature,
    required this.plugin,
    required this.erc20OfInterest,
    required this.abi,
  });
}

class NftInfo {
  final String contractAddress;
  final String collectionName;
  final String data;

  const NftInfo({
    required this.contractAddress,
    required this.collectionName,
    required this.data,
  });
}
