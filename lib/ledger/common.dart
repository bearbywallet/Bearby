class LedgerAccount {
  final String? publicKey;
  final String address;
  final int index;
  final String? chainCode;

  LedgerAccount({
    this.publicKey,
    required this.address,
    required this.index,
    this.chainCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerAccount &&
          runtimeType == other.runtimeType &&
          publicKey == other.publicKey &&
          address == other.address &&
          index == other.index);

  @override
  int get hashCode => Object.hash(publicKey, address, index);

  @override
  String toString() =>
      'LedgerAccount(index: $index, address: $address, '
      'publicKey: ${publicKey == null ? "null" : "0x…"})';
}
