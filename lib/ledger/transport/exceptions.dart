class TransportException implements Exception {
  final String message;
  final String id;
  TransportException(this.message, this.id);

  @override
  String toString() => '$id: $message';
}

class DisconnectedDeviceException extends TransportException {
  DisconnectedDeviceException([String message = 'DisconnectedDevice'])
      : super(message, 'DisconnectedDevice');
}

class DisconnectedDeviceDuringOperationException extends TransportException {
  DisconnectedDeviceDuringOperationException(
      [String message = 'DisconnectedDeviceDuringOperation'])
      : super(message, 'DisconnectedDeviceDuringOperation');
}

class TransportRaceCondition extends TransportException {
  TransportRaceCondition([String message = 'TransportRaceCondition'])
      : super(message, 'TransportRaceCondition');
}

class TransportStatusError extends TransportException {
  final int statusCode;
  TransportStatusError(this.statusCode, [String message = ''])
      : super(message.isEmpty ? 'Status code: $statusCode' : message,
            'TransportStatusError');
}

class StatusCodes {
  static const int ok = 0x9000;
  static const int zilAppVersion = 5;
  static const int zilAppPubKey = 27442;
}
