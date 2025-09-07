import 'package:flutter/foundation.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ethereum/ethereum_eip712_hashed_message_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_personal_message_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_public_key_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_transaction_operation.dart';
import 'package:zilpay/ledger/ethereum/models.dart';
import 'package:zilpay/ledger/ethereum/utils.dart';
import 'package:zilpay/src/rust/api/transaction.dart';
import 'package:zilpay/src/rust/models/transactions/request.dart';

class EthereumLedgerApp {
  final LedgerConnection ledger;
  final LedgerTransformer? transformer;

  EthereumLedgerApp(
    this.ledger, {
    this.transformer,
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
            '[LEDGER_INFO] Transaction requires app settings change or is too complex');
      }

      rethrow;
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
