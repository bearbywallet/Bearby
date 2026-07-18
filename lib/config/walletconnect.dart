/// WalletConnect v2 project configuration for Bearby.
const kWcProjectId = '2cb43be3de5d03d9fdc34b3f4d4b0371';
const kWcAppName = 'Bearby';
const kWcAppDescription = 'Multi-chain crypto wallet';
const kWcAppUrl = 'https://zilpay.io';
const kWcAppIcon = 'https://zilpay.io/favicon.ico';

/// BTC CAIP-2 (bip122 genesis hashes), keyed by provider `chainIds.first`.
const Map<int, String> kBtcCaip2ByChainId = {
  0: 'bip122:000000000019d6689c085ae165831e93', // mainnet
  1: 'bip122:000000000933ea01ad0ee984209779ba', // testnet3
};

/// Solana CAIP-2 by numeric chain id when used in our provider configs.
const Map<int, String> kSolanaCaip2ByChainId = {
  101: 'solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp', // mainnet-beta
  103: 'solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1', // devnet
  1: 'solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1',
};

/// EVM methods we implement for WC sessions.
const List<String> kWcEip155Methods = [
  'personal_sign',
  'eth_sign',
  'eth_signTypedData',
  'eth_signTypedData_v3',
  'eth_signTypedData_v4',
  'eth_sendTransaction',
  'eth_signTransaction',
];

const List<String> kWcSolanaMethods = [
  'solana_signMessage',
  'solana_signTransaction',
  'solana_signAllTransactions',
  'solana_signAndSendTransaction',
];

const List<String> kWcTronMethods = [
  'tron_signMessage',
  'tron_signTransaction',
];

/// WalletConnect Bitcoin (bip122) methods — Reown / AppKit set.
const List<String> kWcBip122Methods = [
  'sendTransfer',
  'getAccountAddresses',
  'signPsbt',
  'signMessage',
];

const List<String> kWcStandardEvents = [
  'chainChanged',
  'accountsChanged',
];

/// bip122-specific address-list change event (AppKit).
const String kWcBip122AddressesChanged = 'bip122_addressesChanged';

const List<String> kWcBip122Events = [
  kWcBip122AddressesChanged,
  'accountsChanged',
  'chainChanged',
];
