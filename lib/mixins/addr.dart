String shortenAddress(String address,
    {int leftSize = 4, int rightSize = 4, int centerSize = 4}) {
  if (address.length < (leftSize + rightSize + centerSize)) {
    return address;
  }

  final left = address.substring(0, leftSize);
  final right = address.substring(address.length - rightSize);
  final centerStart = (address.length - centerSize) ~/ 2;
  final center = address.substring(centerStart, centerStart + centerSize);

  return '$left...$center...$right';
}
