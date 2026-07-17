import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:bearby/config/web3_constants.dart';

/// Reown Dashboard project id (public by design — ships in every wallet).
const String kWalletConnectProjectId = '2cb43be3de5d03d9fdc34b3f4d4b0371';

const String kBearbyNativeScheme = 'bearby://';

final PairingMetadata kBearbyWalletMetadata = PairingMetadata(
  name: 'Bearby Wallet',
  description: 'Bearby multi-chain wallet',
  url: 'https://bearby.io',
  icons: const ['https://bearby.io/icon.png'],
  redirect: Redirect(native: kBearbyNativeScheme),
);

/// Solana CAIP-2 ids are genesis hashes — not derivable from
/// NetworkConfigInfo.chainIds, keyed by Bearby's chainIds.first.
const Map<int, String> kSolanaCaip2ByChainId = {
  101: 'solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp', // mainnet-beta
  1: 'solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1', // devnet
};

/// BTC CAIP-2 ids are genesis hashes (like Solana) — keyed by chainIds.first.
const Map<int, String> kBtcCaip2ByChainId = {
  0: 'bip122:000000000019d6689c085ae165831e93', // mainnet
  1: 'bip122:000000000933ea01ad0ee984209779ba', // testnet3
};

/// Namespace → account addrType (Address::prefix_type).
const Map<String, int> kWcAddrTypeByNamespace = {
  'eip155': kEvmAddressType,
  'solana': kSolanaAddressType,
  'tron': kTronAddressType,
  'bip122': kBtcAddressType,
};

/// v1 consent contract:
/// WalletConnect sessions only expose the **active wallet**'s accounts that
/// match the namespace address family. The connect modal shows that wallet's
/// account picker; multi-wallet / multi-namespace across wallets is v2.
/// Registration deliberately matches this scope (no other-wallet addresses).

const List<String> kWcEvmSigningMethods = [
  'personal_sign',
  'eth_sign',
  'eth_signTypedData_v4',
  'eth_sendTransaction',
  'wallet_switchEthereumChain',
];

const List<String> kWcEvmEvents = ['chainChanged', 'accountsChanged'];

const List<String> kWcSolanaMethods = [
  'solana_getAccounts',
  'solana_requestAccounts',
  'solana_signMessage',
  'solana_signTransaction',
  'solana_signAndSendTransaction',
];

const List<String> kWcTronMethods = [
  'tron_signMessage',
  'tron_signTransaction',
];

const List<String> kWcBtcMethods = [
  'sendTransfer',
  'getAccountAddresses',
  'signPsbt',
  'signMessage',
];

const String kWcBtcAddressesChangedEvent = 'bip122_addressesChanged';

const List<String> kWcBtcEvents = [kWcBtcAddressesChangedEvent];

/// Per-namespace session events (replaces the eip155-only special case).
const Map<String, List<String>> kWcEventsByNamespace = {
  'eip155': kWcEvmEvents,
  'bip122': kWcBtcEvents,
};

/// Tron docs: enables the flat {address, transaction} request format.
const Map<String, String> kWcTronSessionProperties = {
  'tron_method_version': 'v1',
};

/// Session property key for the bip122 addresses payload (spec recommendation).
const String kWcBtcAddressesProperty = 'bip122_getAccountAddresses';

/// BIP purpose → `AddressType::to_byte()` used by `getBtcAddresses` map keys.
const Map<int, int> kBtcAddrTypeByBip = {
  44: 0, // P2PKH
  49: 1, // P2SH-P2WPKH
  84: 2, // P2WPKH
  86: 4, // P2TR
};

/// Payloads larger than this are parsed off the main isolate.
const int kWcIsolatePayloadThreshold = 16 * 1024;
