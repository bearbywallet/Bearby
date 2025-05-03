class ZilLedgerAccount {
  final String publicKey;
  final String address;
  final int index;

  ZilLedgerAccount({
    required this.publicKey,
    required this.address,
    required this.index,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ZilLedgerAccount &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey &&
          index == other.index);

  @override
  int get hashCode => Object.hash(publicKey, index);
}
