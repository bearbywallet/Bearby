enum TronWeb3Method {
  getInitProviderData('getInitProviderData'),
  unknown('unknown');

  final String value;
  const TronWeb3Method(this.value);

  static TronWeb3Method fromValue(String? value) {
    return TronWeb3Method.values.firstWhere(
      (m) => m.value == value,
      orElse: () => TronWeb3Method.unknown,
    );
  }
}

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
