String viewIcon(String addr, String theme) {
  final zilAddr =
      addr == 'zil1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq9yf6pz' ? 'ZIL' : addr;
  final color = theme == 'Dark' ? 'dark' : 'light';

  return 'https://meta.viewblock.io/zilliqa.$zilAddr/logo?t=$color';
}
