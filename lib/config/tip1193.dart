enum TronWeb3ErrorCode {
  userRejected(4001),
  unauthorized(4100),
  unsupportedMethod(4200),
  disconnected(4900),
  internalError(-32603),
  invalidInput(-32000),
  resourceUnavailable(-32002);

  final int code;
  const TronWeb3ErrorCode(this.code);
}
