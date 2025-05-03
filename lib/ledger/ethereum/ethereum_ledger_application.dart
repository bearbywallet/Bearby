import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:zilpay/ledger/common.dart';
import 'package:zilpay/ledger/ethereum/ethereum_eip712_hashed_message_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_personal_message_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_public_key_operation.dart';
import 'package:zilpay/ledger/ethereum/ethereum_transaction_operation.dart';
import 'package:zilpay/ledger/ethereum/models.dart';
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
    final txRLP = await encodeTxRlp(
      tx: transaction,
      walletIndex: BigInt.from(walletIndex),
      accountIndex: BigInt.from(accountIndex),
    );
    final signatureBytes = await ledger.sendOperation<Uint8List>(
      EthereumTransactionOperation(
        accountIndex: accountIndex,
        transaction: txRLP,
      ),
      transformer: transformer,
    );

    _checkResult(signatureBytes);

    return EthLedgerSignature.fromLedgerResponse(signatureBytes);
  }

  static void _checkResult(Uint8List result) {
    if (result.length != 2) {
      return;
    }

    int status = (result[0] << 8) | result[1];

    switch (status) {
      case 0x9000: // APDU_RESPONSE_OK
        break;

      case 0x5515:
        throw Exception('Device is locked');

      case 0x6967:
        throw Exception('Operation rejected');

      case 0x6985: // APDU_RESPONSE_CONDITION_NOT_SATISFIED
        throw Exception('Condition not satisfied (possibly rejected by user)');

      case 0x0000: // APDU_NO_RESPONSE
        throw Exception('No response from device');

      case 0x6001: // APDU_RESPONSE_MODE_CHECK_FAILED
        throw Exception('Mode check failed');

      case 0x6501: // APDU_RESPONSE_TX_TYPE_NOT_SUPPORTED
        throw Exception('Transaction type not supported');

      case 0x6502: // APDU_RESPONSE_CHAINID_OUT_BUF_SMALL
        throw Exception('Chain ID buffer too small');

      case 0x6800: // APDU_RESPONSE_INTERNAL_ERROR
        throw Exception('Internal device error');

      case 0x6982: // APDU_RESPONSE_SECURITY_NOT_SATISFIED
        throw Exception('Security conditions not satisfied');

      case 0x6983: // APDU_RESPONSE_WRONG_DATA_LENGTH
        throw Exception('Incorrect data length');

      case 0x6984: // APDU_RESPONSE_PLUGIN_NOT_INSTALLED
        throw Exception('Plugin not installed');

      case 0x6a00: // APDU_RESPONSE_ERROR_NO_INFO
        throw Exception('Error with no additional information');

      case 0x6a80: // APDU_RESPONSE_INVALID_DATA
        throw Exception('Invalid data');

      case 0x6a84: // APDU_RESPONSE_INSUFFICIENT_MEMORY
        throw Exception('Insufficient memory');

      case 0x6a88: // APDU_RESPONSE_REF_DATA_NOT_FOUND
        throw Exception('Reference data not found');

      case 0x6b00: // APDU_RESPONSE_INVALID_P1_P2
        throw Exception('Invalid P1 or P2 parameters');

      case 0x6d00: // APDU_RESPONSE_INVALID_INS
        throw Exception('Invalid instruction');

      case 0x6e00: // APDU_RESPONSE_INVALID_CLA
        throw Exception('Invalid class');

      case 0x6f00: // APDU_RESPONSE_UNKNOWN
        throw Exception('Unknown error');

      case 0x911c: // APDU_RESPONSE_CMD_CODE_NOT_SUPPORTED
        throw Exception('Command code not supported');

      default:
        throw Exception(
            'Unknown status code: 0x${status.toRadixString(16).padLeft(4, '0')}');
    }
  }
}
