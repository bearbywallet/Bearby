class CryptoQrGenerator {
  static String generateEVMQr({
    required String address,
    String? amount,
    int chainId = 1,
    String? token,
    String? gasLimit,
    String? gasPrice,
    String? chainName = "ethereum",
  }) {
    if (!_isValidEthereumAddress(address)) {
      throw ArgumentError('Invalid Ethereum address');
    }

    String uri = 'ethereum:${address.toLowerCase()}';

    if (token != null) {
      if (!_isValidEthereumAddress(token)) {
        throw ArgumentError('Invalid token address');
      }
      uri =
          '$chainName:${token.toLowerCase()}/transfer?address=${address.toLowerCase()}';
    }

    List<String> params = [];

    if (amount != null) {
      params.add('value=$amount');
    }

    if (chainId != 1) {
      params.add('chainId=$chainId');
    }

    if (gasLimit != null) {
      params.add('gasLimit=$gasLimit');
    }

    if (gasPrice != null) {
      params.add('gasPrice=$gasPrice');
    }

    if (params.isNotEmpty) {
      uri += token == null ? '?' : '&';
      uri += params.join('&');
    }

    return uri;
  }

  static String generateZilliqaQr({
    required String address,
    String? amount,
    String? token,
  }) {
    String uri = 'zilliqa:${address.toLowerCase()}';
    List<String> params = [];

    if (token != null) {
      uri =
          'zilliqa:${token.toLowerCase()}/transfer?address=${address.toLowerCase()}';
    }

    if (amount != null) {
      params.add('amount=$amount');
    }

    if (params.isNotEmpty) {
      uri += token == null ? '?' : '&';
      uri += params.join('&');
    }

    return uri;
  }

  static bool _isValidEthereumAddress(String address) {
    RegExp ethAddressRegExp = RegExp(r'^0x[0-9a-fA-F]{40}$');
    return ethAddressRegExp.hasMatch(address);
  }
}
