import 'package:flutter/foundation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ethereum/ethereum_eip712_hashed_message_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_personal_message_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_public_key_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_transaction_operation.dart';
import 'package:zilpay/ledger/ethereum/ledger_resolver.dart';
import 'package:zilpay/ledger/ethereum/models.dart';
import 'package:zilpay/ledger/ethereum/utils.dart';
import 'package:zilpay/ledger/ethereum/resolution_types.dart';
import 'package:zilpay/ledger/ethereum/provision_operations.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';

class EthereumLedgerApp {
  final LedgerConnection ledger;
  final LedgerTransformer? transformer;
  final LoadConfig loadConfig;

  EthereumLedgerApp(
    this.ledger, {
    this.transformer,
    this.loadConfig = const LoadConfig(),
  });

  Future<List<LedgerAccount>> getAccounts(List<int> accountIndices) async {
    final List<LedgerAccount> accounts = [];

    for (final index in accountIndices) {
      final account = await ledger.sendOperation<LedgerAccount>(
        EthereumPublicKeyOperation(accountIndex: index),
        transformer: transformer,
      );
      accounts.add(account);
    }

    return accounts;
  }

  Future<EthLedgerSignature> signPersonalMessage(
    Uint8List message,
    int accountIndex,
  ) async {
    final signatureBytes = await ledger.sendOperation<Uint8List>(
      EthereumPersonalMessageOperation(
          accountIndex: accountIndex, message: message),
      transformer: transformer,
    );

    _checkResult(signatureBytes);

    return EthLedgerSignature.fromLedgerResponse(signatureBytes);
  }

  Future<EthLedgerSignature> signEIP712HashedMessage(
    Eip712Hashes hashes,
    int accountIndex,
  ) async {
    final signatureBytes = await ledger.sendOperation<Uint8List>(
      EthereumEIP712HashedMessageOperation(
        accountIndex: accountIndex,
        domainSeparator: hashes.domainSeparator,
        hashStructMessage: hashes.hashStructMessage,
      ),
      transformer: transformer,
    );

    _checkResult(signatureBytes);

    return EthLedgerSignature.fromLedgerResponse(signatureBytes);
  }

  Future<EthLedgerSignature> clearSignTransaction(
    TransactionRequestInfo transaction,
    int walletIndex,
    int accountIndex, {
    ResolutionConfig? resolutionConfig,
  }) async {
    final config = resolutionConfig ??
        const ResolutionConfig(
          erc20: true,
          externalPlugins: true,
          nft: false,
          uniswapV3: false,
        );

    try {
      debugPrint('[LEDGER_DEBUG] Starting transaction resolution...');
      debugPrint('[LEDGER_DEBUG] Resolution config:');
      debugPrint('[LEDGER_DEBUG]   ERC20: ${config.erc20}');
      debugPrint(
          '[LEDGER_DEBUG]   External Plugins: ${config.externalPlugins}');
      debugPrint('[LEDGER_DEBUG]   NFT: ${config.nft}');
      debugPrint('[LEDGER_DEBUG]   UniswapV3: ${config.uniswapV3}');

      final resolution = await LedgerTransactionResolver.resolveTransaction(
        transaction,
        loadConfig,
        config,
      );

      debugPrint('[LEDGER_DEBUG] Resolution completed:');
      debugPrint(
          '[LEDGER_DEBUG]   ERC20 tokens: ${resolution.erc20Tokens.length}');
      debugPrint('[LEDGER_DEBUG]   NFTs: ${resolution.nfts.length}');
      debugPrint(
          '[LEDGER_DEBUG]   External plugins: ${resolution.externalPlugin.length}');
      debugPrint('[LEDGER_DEBUG]   Plugins: ${resolution.plugin.length}');
      debugPrint('[LEDGER_DEBUG]   Domains: ${resolution.domains.length}');

      await _provideResolutionData(resolution);

      return await signTransaction(transaction, walletIndex, accountIndex);
    } catch (e) {
      debugPrint(
          '[LEDGER_ERROR] Resolution failed, falling back to blind signing: $e');
      return await signTransaction(transaction, walletIndex, accountIndex);
    }
  }

  Future<EthLedgerSignature> signTransaction(
    TransactionRequestInfo transaction,
    int walletIndex,
    int accountIndex,
  ) async {
    try {
      debugPrint('[LEDGER_DEBUG] Starting transaction signing process...');
      debugPrint(
          '[LEDGER_DEBUG] Wallet index: $walletIndex, Account index: $accountIndex');

      final EncodedRLPTx txRLP = await encodeTxRlp(
        tx: transaction,
        walletIndex: BigInt.from(walletIndex),
        accountIndex: BigInt.from(accountIndex),
      );

      debugPrint(
          '[LEDGER_DEBUG] Raw TX RLP (${txRLP.bytes.length} bytes): ${bytesToHex(txRLP.bytes)}');
      debugPrint('[LEDGER_DEBUG] Chunks count: ${txRLP.chunksBytes.length}');

      final signatureBytes = await ledger.sendOperation<Uint8List>(
        EthereumTransactionOperation(
          accountIndex: accountIndex,
          transactionRlp: txRLP.bytes,
          transactionChunks: txRLP.chunksBytes,
          connectionType: ledger.connectionType,
        ),
        transformer: transformer,
      );

      debugPrint(
          '[LEDGER_DEBUG] Received signature bytes (${signatureBytes.length} bytes): ${bytesToHex(signatureBytes)}');

      final signature = EthLedgerSignature.fromLedgerResponse(signatureBytes);

      debugPrint('[LEDGER_DEBUG] Parsed signature:');
      debugPrint(
          '[LEDGER_DEBUG]   v: ${signature.v} (0x${signature.v.toRadixString(16)})');
      debugPrint('[LEDGER_DEBUG]   r: ${bytesToHex(signature.r)}');
      debugPrint('[LEDGER_DEBUG]   s: ${bytesToHex(signature.s)}');
      debugPrint(
          '[LEDGER_DEBUG] Full signature hex: ${signature.toHexString()}');

      return signature;
    } catch (e) {
      debugPrint('[LEDGER_ERROR] Transaction signing failed: $e');

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('0x6a80') ||
          errorStr.contains('0x6985') ||
          errorStr.contains('contract data') ||
          errorStr.contains('blind signing')) {
        debugPrint(
            '[LEDGER_INFO] Transaction requires app settings change or clear signing data');
        debugPrint(
            '[LEDGER_INFO] Please enable "Blind signing" or "Contract data" in Ethereum app settings');
      }

      rethrow;
    }
  }

  Future<void> _provideResolutionData(
      LedgerEthTransactionResolution resolution) async {
    try {
      debugPrint('[LEDGER_DEBUG] Providing resolution data to device...');

      for (final domain in resolution.domains) {
        debugPrint('[LEDGER_DEBUG] Providing domain: ${domain.domain}');
        await ledger.sendOperation<bool>(
          EthereumProvideDomainNameOperation(data: domain.domain),
          transformer: transformer,
        );
      }

      for (final plugin in resolution.plugin) {
        debugPrint('[LEDGER_DEBUG] Providing plugin data');
        await ledger.sendOperation<bool>(
          EthereumSetPluginOperation(data: plugin),
          transformer: transformer,
        );
      }

      for (final externalPlugin in resolution.externalPlugin) {
        debugPrint('[LEDGER_DEBUG] Providing external plugin data');
        await ledger.sendOperation<bool>(
          EthereumSetExternalPluginOperation(
            payload: externalPlugin.payload,
            signature: externalPlugin.signature,
          ),
          transformer: transformer,
        );
      }

      for (final nft in resolution.nfts) {
        debugPrint('[LEDGER_DEBUG] Providing NFT information');
        await ledger.sendOperation<bool>(
          EthereumProvideNFTInformationOperation(data: nft),
          transformer: transformer,
        );
      }

      for (final erc20Token in resolution.erc20Tokens) {
        debugPrint(
            '[LEDGER_DEBUG] Providing ERC20 token information: ${erc20Token.substring(0, 20)}...');
        await ledger.sendOperation<bool>(
          EthereumProvideERC20TokenOperation(data: erc20Token),
          transformer: transformer,
        );
      }

      debugPrint('[LEDGER_DEBUG] All resolution data provided successfully');
    } catch (e) {
      debugPrint('[LEDGER_ERROR] Failed to provide resolution data: $e');
    }
  }

  static void _checkResult(Uint8List result) {
    if (result.length < 2) {
      return;
    }

    int status = (result[result.length - 2] << 8) | result[result.length - 1];

    switch (status) {
      case 0x9000:
        break;
      case 0x5515:
        throw Exception('Device is locked');
      case 0x6967:
        throw Exception('Operation rejected by user');
      case 0x6985:
        throw Exception(
            'Transaction rejected by user or requires plugin/clear signing setup');
      case 0x0000:
        throw Exception('No response from device');
      case 0x6001:
        throw Exception('Mode check failed');
      case 0x6501:
        throw Exception('Transaction type not supported');
      case 0x6502:
        throw Exception('Chain ID buffer too small');
      case 0x6800:
        throw Exception('Internal device error');
      case 0x6982:
        throw Exception('Security conditions not satisfied');
      case 0x6983:
        throw Exception('Incorrect data length');
      case 0x6984:
        throw Exception('Plugin not installed');
      case 0x6a00:
        throw Exception('Error with no additional information');
      case 0x6a80:
        throw Exception(
            'Invalid data. Enable "Blind signing" or "Contract data" in Ethereum app settings');
      case 0x6a84:
        throw Exception('Insufficient memory');
      case 0x6a88:
        throw Exception('Reference data not found');
      case 0x6b00:
        throw Exception('Invalid P1 or P2 parameters');
      case 0x6d00:
        throw Exception('Invalid instruction');
      case 0x6e00:
        throw Exception('Invalid class');
      case 0x6f00:
        throw Exception('Unknown error');
      case 0x911c:
        throw Exception('Command code not supported');
      default:
        String hexStatus = status.toRadixString(16).padLeft(4, '0');
        if (status == 0x6985 || status == 0x6a80) {
          throw Exception(
              'Transaction rejected (0x$hexStatus). Enable "Blind signing" or "Contract data" in Ethereum app settings');
        }
        throw Exception('Unknown status code: 0x$hexStatus');
    }
  }
}
