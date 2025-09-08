import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:zilpay/ledger/ethereum/resolution_types.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';
import 'erc20_service.dart';

class LedgerTransactionResolver {
  static Future<LedgerEthTransactionResolution> resolveTransaction(
    TransactionRequestInfo transaction,
    LoadConfig loadConfig,
    ResolutionConfig resolutionConfig,
  ) async {
    final resolutions = <LedgerEthTransactionResolution>[];

    final evmTx = transaction.evm;
    if (evmTx == null) {
      return const LedgerEthTransactionResolution();
    }

    final contractAddress = evmTx.to?.toLowerCase();
    if (contractAddress == null) {
      return const LedgerEthTransactionResolution();
    }

    final data = evmTx.data;
    String? selector;
    if (data != null && data.length >= 4) {
      final dataBytes = Uint8List.fromList(data);
      if (dataBytes.length >= 4) {
        selector =
            '0x${dataBytes.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
      }
    }

    if (selector != null && evmTx.chainId != null) {
      final chainId = evmTx.chainId!.toInt();

      final shouldResolve = _PotentialResolutions(
        token: resolutionConfig.erc20 &&
            ERC20Selectors.clearSignedSelectors.contains(selector),
        nft: resolutionConfig.nft && _isNFTSelector(selector),
        externalPlugins: resolutionConfig.externalPlugins,
        uniswapV3: resolutionConfig.uniswapV3,
      );

      final pluginsResolution = await _loadNanoAppPlugins(
        contractAddress,
        selector,
        transaction,
        chainId,
        loadConfig,
        shouldResolve,
      );
      resolutions.add(pluginsResolution);

      final contractResolution = await _getAdditionalDataForContract(
        contractAddress,
        chainId,
        loadConfig,
        shouldResolve,
      );
      resolutions.add(contractResolution);
    }

    if (resolutionConfig.domains.isNotEmpty) {
      resolutions.add(LedgerEthTransactionResolution(
        domains: resolutionConfig.domains,
      ));
    }

    return LedgerEthTransactionResolution.merge(resolutions);
  }

  static Future<LedgerEthTransactionResolution> _getAdditionalDataForContract(
    String contractAddress,
    int chainId,
    LoadConfig loadConfig,
    _PotentialResolutions shouldResolve,
  ) async {
    final resolution = LedgerEthTransactionResolution();

    if (shouldResolve.nft) {
      final nftInfo = await _getNFTInfo(contractAddress, chainId, loadConfig);
      if (nftInfo != null) {
        print(
            'Loaded NFT info for ${nftInfo.contractAddress} (${nftInfo.collectionName})');
        return resolution.copyWith(nfts: [nftInfo.data]);
      }
    }

    if (shouldResolve.token) {
      print('[RESOLVER_DEBUG] Loading ERC20 signatures for chain $chainId...');
      final erc20SignaturesBlob = await ERC20Service.findERC20SignaturesInfo(
        loadConfig,
        chainId,
      );

      if (erc20SignaturesBlob != null) {
        print(
            '[RESOLVER_DEBUG] ERC20 signatures blob loaded, length: ${erc20SignaturesBlob.length}');

        final erc20Info = ERC20Service.byContractAddressAndChainId(
          contractAddress,
          chainId,
          erc20SignaturesBlob,
        );

        if (erc20Info != null) {
          print(
              '[RESOLVER_DEBUG] Loaded ERC20 token info for ${erc20Info.contractAddress} (${erc20Info.ticker})');
          print('[RESOLVER_DEBUG] Token decimals: ${erc20Info.decimals}');
          print(
              '[RESOLVER_DEBUG] Token data length: ${erc20Info.data.length} bytes');

          final hexData = erc20Info.data
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();
          print('[RESOLVER_DEBUG] Hex data: ${hexData.substring(0, 40)}...');

          return resolution.copyWith(erc20Tokens: [hexData]);
        } else {
          print(
              '[RESOLVER_DEBUG] No ERC20 info found for contract $contractAddress on chain $chainId');
        }
      } else {
        print('[RESOLVER_DEBUG] Failed to load ERC20 signatures blob');
      }
    }

    return resolution;
  }

  static Future<LedgerEthTransactionResolution> _loadNanoAppPlugins(
    String contractAddress,
    String selector,
    TransactionRequestInfo transaction,
    int chainId,
    LoadConfig loadConfig,
    _PotentialResolutions shouldResolve,
  ) async {
    var resolution = const LedgerEthTransactionResolution();

    if (shouldResolve.nft) {
      final nftPluginPayload = await _loadNftPlugin(
        contractAddress,
        selector,
        chainId,
        loadConfig,
      );

      if (nftPluginPayload != null) {
        resolution = resolution.copyWith(plugin: [nftPluginPayload]);
      }
    }

    if (shouldResolve.externalPlugins) {
      final contractMethodInfos = await _loadInfosForContractMethod(
        contractAddress,
        selector,
        chainId,
        loadConfig,
      );

      if (contractMethodInfos != null) {
        final plugin = contractMethodInfos.plugin;
        if (plugin.isNotEmpty) {
          print('Found plugin ($plugin) for selector: $selector');
          resolution = resolution.copyWith(
            externalPlugin: [
              ExternalPlugin(
                payload: contractMethodInfos.payload,
                signature: contractMethodInfos.signature,
              ),
            ],
          );
        }
      }
    }

    return resolution;
  }

  static Future<NftInfo?> _getNFTInfo(
    String contractAddress,
    int chainId,
    LoadConfig loadConfig,
  ) async {
    final nftExplorerBaseURL = loadConfig.nftExplorerBaseURL;
    if (nftExplorerBaseURL == null) return null;

    final url = '$nftExplorerBaseURL/$chainId/contracts/$contractAddress';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final payload = data['payload'] as String;

        final collectionNameLength =
            int.parse(payload.substring(4, 6), radix: 16);
        final collectionNameHex =
            payload.substring(6, 6 + collectionNameLength * 2);

        String collectionName = '';
        for (int i = 0; i < collectionNameHex.length; i += 2) {
          final charCode =
              int.parse(collectionNameHex.substring(i, i + 2), radix: 16);
          collectionName += String.fromCharCode(charCode);
        }

        return NftInfo(
          contractAddress: contractAddress,
          collectionName: collectionName,
          data: payload,
        );
      }

      print(
          'Error: could not fetch NFT info from $url: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error: could not fetch NFT info from $url: $e');
      return null;
    }
  }

  static Future<String?> _loadNftPlugin(
    String contractAddress,
    String selector,
    int chainId,
    LoadConfig loadConfig,
  ) async {
    final nftExplorerBaseURL = loadConfig.nftExplorerBaseURL;
    if (nftExplorerBaseURL == null) return null;

    final url =
        '$nftExplorerBaseURL/$chainId/contracts/$contractAddress/plugin-selector/$selector';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['payload'] as String;
      }

      return null;
    } catch (e) {
      print('Error: could not fetch NFT plugin from $url: $e');
      return null;
    }
  }

  static Future<ContractMethod?> _loadInfosForContractMethod(
    String contractAddress,
    String selector,
    int chainId,
    LoadConfig loadConfig,
  ) async {
    final pluginBaseURL = loadConfig.pluginBaseURL;
    if (pluginBaseURL == null) return null;

    final url = '$pluginBaseURL/plugins/ethereum.json';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        Map<String, dynamic> mergedData = Map.from(data);
        if (loadConfig.extraPlugins != null) {
          mergedData.addAll(loadConfig.extraPlugins!);
        }

        final lcSelector = selector.toLowerCase();
        final lcContractAddress = contractAddress.toLowerCase();

        if (mergedData.containsKey(lcContractAddress)) {
          final contractSelectors =
              mergedData[lcContractAddress] as Map<String, dynamic>;

          if (contractSelectors.containsKey(lcSelector)) {
            final selectorData =
                contractSelectors[lcSelector] as Map<String, dynamic>;

            return ContractMethod(
              payload: selectorData['serialized_data'] as String,
              signature: selectorData['signature'] as String,
              plugin: selectorData['plugin'] as String,
              erc20OfInterest:
                  List<String>.from(selectorData['erc20OfInterest'] as List),
              abi: contractSelectors['abi'] as Map<String, dynamic>,
            );
          }
        }
      }

      return null;
    } catch (e) {
      print('Error: could not fetch contract method info from $url: $e');
      return null;
    }
  }

  static bool _isNFTSelector(String selector) {
    const nftSelectors = [
      '0x42842e0e', // safeTransferFrom(address,address,uint256)
      '0xb88d4fde', // safeTransferFrom(address,address,uint256,bytes)
      '0x23b872dd', // transferFrom(address,address,uint256)
      '0xf242432a', // safeTransferFrom(address,address,uint256,uint256,bytes) - ERC1155
      '0x2eb2c2d6', // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes) - ERC1155
    ];

    return nftSelectors.contains(selector);
  }
}

class _PotentialResolutions {
  final bool token;
  final bool nft;
  final bool externalPlugins;
  final bool uniswapV3;

  const _PotentialResolutions({
    required this.token,
    required this.nft,
    required this.externalPlugins,
    required this.uniswapV3,
  });
}
