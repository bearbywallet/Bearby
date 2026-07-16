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

/// Namespace → account addrType (Address::prefix_type).
const Map<String, int> kWcAddrTypeByNamespace = {
  'eip155': kEvmAddressType,
  'solana': kSolanaAddressType,
  'tron': kTronAddressType,
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

/// Tron docs: enables the flat {address, transaction} request format.
const Map<String, String> kWcTronSessionProperties = {
  'tron_method_version': 'v1',
};

/// Payloads larger than this are parsed off the main isolate.
const int kWcIsolatePayloadThreshold = 16 * 1024;
