class EthLedgerAccount {
  final String publicKey;
  final String address;
  final int index;

  EthLedgerAccount({
    required this.publicKey,
    required this.address,
    required this.index,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EthLedgerAccount &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey &&
          index == other.index);

  @override
  int get hashCode => Object.hash(publicKey, index);
}
