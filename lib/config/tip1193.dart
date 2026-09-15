import 'package:bearby/web3/web3_response.dart';

export 'package:bearby/web3/web3_response.dart'
    show Web3ErrorCode, sendWeb3Response;

enum TronWeb3ErrorCode implements Web3ErrorCode {
  userRejected(4001),
  unauthorized(4100),
  unsupportedMethod(4200),
  disconnected(4900),
  internalError(-32603),
  invalidInput(-32000),
  resourceUnavailable(-32002);

  @override

  final int code;
  const TronWeb3ErrorCode(this.code);
}
