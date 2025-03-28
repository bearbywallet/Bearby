import 'package:zilpay/src/rust/models/ftoken.dart';
import 'package:zilpay/src/rust/models/provider.dart';

String selectVariant(String? theme, List<String> options) {
  if (options.isEmpty) return '';
  if (theme == 'Light') return options[0];
  if (theme == 'Dark' && options.length >= 2) return options[1];
  return options[0];
}

String processUrl(String template, String? theme) {
  final regex = RegExp(r'%\{(\w+)\(([^)]+)\)\}%');
  return template.replaceAllMapped(regex, (match) {
    String optionsStr = match.group(2)!;
    List<String> options = optionsStr.split(',').map((s) => s.trim()).toList();
    return selectVariant(theme, options);
  });
}

String processUrlTemplate({
  required String template,
  required String theme,
  Map<String, String> replacements = const {},
}) {
  if (!template.contains('%{')) return template;

  String processed = template;

  final funcRegex = RegExp(r'%\{(\w+)\(([^)]+)\)\}%');
  processed = processed.replaceAllMapped(funcRegex, (match) {
    String optionsStr = match.group(2)!;
    List<String> options = optionsStr.split(',').map((s) => s.trim()).toList();

    if (options.isEmpty) return '';
    if (theme == 'Light') return options[0];
    if (theme == 'Dark' && options.length >= 2) return options[1];
    return options[0];
  });

  if (processed.contains('%{dark,light}%')) {
    processed = processed.replaceAll(
        '%{dark,light}%', theme == 'Dark' ? 'light' : 'dark');
  }

  for (final entry in replacements.entries) {
    processed = processed.replaceAll('%{${entry.key}}%', entry.value);
  }

  return processed;
}

String processTokenLogo({
  required FTokenInfo token,
  required String shortName,
  required String theme,
}) {
  if (token.logo == null) return 'assets/icons/warning.svg';

  final replacements = <String, String>{
    'symbol': token.symbol.toLowerCase(),
    'contract_address': token.addr.toLowerCase(),
    'name': token.name,
    'shortName': shortName,
  };

  return processUrlTemplate(
    template: token.logo!,
    theme: theme,
    replacements: replacements,
  );
}

String formExplorerUrl(ExplorerInfo explorer, String transactionHash) {
  final baseUrl = explorer.url.endsWith('/')
      ? explorer.url.substring(0, explorer.url.length - 1)
      : explorer.url;

  return "$baseUrl/tx/$transactionHash";
}

String viewChain({
  required NetworkConfigInfo network,
  required String theme,
}) {
  const defaultIcon = 'assets/icons/default_chain.svg';

  if (network.logo.isEmpty) return defaultIcon;

  final replacements = <String, String>{
    'shortName': network.shortName.toLowerCase(),
  };

  return processUrlTemplate(
    template: network.logo,
    theme: theme,
    replacements: replacements,
  );
}
