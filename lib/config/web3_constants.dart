// Response types
const String kBearbyResponseType = 'BEARBY_RESPONSE';

// Event names
const String kAccountsChangedEvent = 'accountsChanged';
const String kChainChangedEvent = 'chainChanged';

// Network identifiers
const int kBitcoinlip44 = 0;
const int kZilliqaSlip44 = 313;
const int kEthereumSlip44 = 60;
final BigInt kZilliqaChainId = BigInt.one;

// Address types
const int kScillaAddressType = 0;
const int kEvmAddressType = 1;

// JSON-RPC
const String kJsonRpcVersion = '2.0';

// Token types
const String kErc20TokenType = 'ERC20';

// Protocol
const String kHttpsProtocol = 'https';

// Asset paths
const String kMainnetChainsPath = 'assets/chains/mainnet-chains.json';
const String kTestnetChainsPath = 'assets/chains/testnet-chains.json';

// Default values
const int kDefaultEvmDecimals = 18;
const List<int> kDefaultEvmFeatures = [155, 1559, 4844];

// Gas price multipliers
const int kGasPriceMultiplierLow = 120;
const int kGasPriceMultiplierMarket = 150;
const int kGasPriceMultiplierAggressive = 200;

// Testnet identifier
const String kTestnetIdentifier = 'test';

// Permission constants
const String kEthAccountsPermission = 'eth_accounts';
const String kParentCapabilityKey = 'parentCapability';
const String kCaveatsKey = 'caveats';
const String kFilterResponseType = 'filterResponse';
const String kPermissionsKey = 'permissions';
const String kTypeKey = 'type';
const String kValueKey = 'value';

// Explorer
const String kDefaultExplorerName = 'Explorer';
const int kDefaultExplorerStandard = 0;

// Transaction EVM
const String kEvmTransactionTitle = 'EVM Transaction';

// Sign message titles
const String kSignMessageTitle = 'Sign Message';
const String kSignEthereumMessageTitle = 'Sign Ethereum Message';
const String kSignTypedDataTitle = 'Sign Typed Data';

// Method parameter names
const String kParamFrom = 'from';
const String kParamTo = 'to';
const String kParamChainId = 'chainId';
const String kParamGas = 'gas';
const String kParamGasPrice = 'gasPrice';
const String kParamMaxFeePerGas = 'maxFeePerGas';
const String kParamMaxPriorityFeePerGas = 'maxPriorityFeePerGas';
const String kParamValue = 'value';
const String kParamData = 'data';
const String kParamNativeCurrency = 'nativeCurrency';
const String kParamRpcUrls = 'rpcUrls';
const String kParamBlockExplorerUrls = 'blockExplorerUrls';
const String kParamChainName = 'chainName';
const String kParamOptions = 'options';
const String kParamAddress = 'address';
const String kParamSymbol = 'symbol';
const String kParamDecimals = 'decimals';
const String kParamImage = 'image';
const String kParamName = 'name';

// Hex prefix
const String kHexPrefix = '0x';
const String kHexZero = '0x0';
const String kHexOne = '0x1';
const int kHexRadix = 16;
