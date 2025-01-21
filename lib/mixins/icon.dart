import 'package:zilpay/src/rust/models/ftoken.dart';

String cnd =
    "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/svg";

String viewTokenIcon(FTokenInfo token, BigInt chainId, String? theme) {
  if (token.native) {
    return chainIcon(token.symbol, theme);
  }

  switch (chainId.toInt()) {
    case 32770: // ZIL
      final color = theme == 1 ? 'dark' : 'light';
      return 'https://meta.viewblock.io/zilliqa.${token.addr}/logo?t=$color';
    case 56: // BSC
      return "https://pancakeswap.finance/images/tokens/${token.addr}.png";
    case 1: // ETH
      return "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/${token.addr}/logo.png";
    default:
      return "";
  }
}

String chainIcon(String symbol, String? theme) {
  if (symbol.startsWith("t")) {
    symbol = symbol.replaceFirst("t", "");
  }

  String color = theme == null
      ? "color"
      : theme == "Light"
          ? 'black'
          : 'white';

  return "$cnd/$color/$symbol.svg".toLowerCase();
}
