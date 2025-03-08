String shortenAddress(String address, {int leftSize = 6, int rightSize = 3}) {
  if (address.length < (leftSize + rightSize)) {
    return address;
  }

  final left = address.substring(0, leftSize);
  final right = address.substring(address.length - rightSize);

  return '$left..$right';
}
