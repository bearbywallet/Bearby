import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/provider.dart';

String selectVariant(String? theme, List<String> options) {
  if (options.isEmpty) return '';
  if (theme == 'light') return options[0];
  if (theme == 'dark' && options.length >= 2) return options[1];
  return options[0];
}

String preprocessUrl(String template, String? theme) {
  final regex = RegExp(r'%\{(\w+)\(([^)]+)\)\}%');
  return template.replaceAllMapped(regex, (match) {
    String optionsStr = match.group(2)!;
    List<String> options = optionsStr.split(',').map((s) => s.trim()).toList();
    return selectVariant(theme, options);
  });
}

String processTokenLogo(FTokenInfo token, String? theme) {
  if (token.logo == null) return 'assets/icons/warning.svg';

  String logo = token.logo!;

  if (!logo.contains('%{')) return logo;

  String processed = preprocessUrl(logo, theme);

  return processed
      .replaceAll('%{symbol}%',
          token.symbol.replaceAll("t", "").replaceAll("p", "").toLowerCase())
      .replaceAll('%{contract_address}%', token.addr.toLowerCase())
      .replaceAll('%{name}%', token.name);
}

String formExplorerUrl(ExplorerInfo explorer, String transactionHash) {
  final baseUrl = explorer.url.endsWith('/')
      ? explorer.url.substring(0, explorer.url.length - 1)
      : explorer.url;

  return "$baseUrl/tx/$transactionHash";
}
