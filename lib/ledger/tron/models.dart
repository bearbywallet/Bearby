class TronAppConfiguration {
  final bool allowData;
  final bool allowContract;
  final bool truncateAddress;
  final bool signByHash;
  final String version;

  TronAppConfiguration({
    required this.allowData,
    required this.allowContract,
    required this.truncateAddress,
    required this.signByHash,
    required this.version,
  });
}
