String viewIcon(String addr, int theme, BigInt chainID) {
  switch (chainID.toInt()) {
    case 32770: // ZIL
      final zilAddr =
          addr == 'zil1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq9yf6pz' ? 'ZIL' : addr;
      final color = theme == 1 ? 'dark' : 'light';

      return 'https://meta.viewblock.io/zilliqa.$zilAddr/logo?t=$color';
    case 56: // BSC
      return "https://pancakeswap.finance/images/tokens/$addr.png";
    case 1: // ETH
      return "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/$addr/logo.png";
    default:
      return "";
  }
}
