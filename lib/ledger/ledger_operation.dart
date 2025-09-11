import 'dart:typed_data';
import 'package:zilpay/ledger/transport/transport.dart';
import 'package:zilpay/ledger/transport/exceptions.dart';

class ByteDataWriter {
  final List<int> _bytes = [];
  final Endian endian;

  ByteDataWriter({this.endian = Endian.big});

  void writeUint8(int value) {
    _bytes.add(value & 0xff);
  }

  void writeInt32(int value) {
    final byteData = ByteData(4);
    byteData.setInt32(0, value, endian);
    _bytes.addAll(byteData.buffer.asUint8List());
  }

  void writeUint32(int value) {
    final byteData = ByteData(4);
    byteData.setUint32(0, value, endian);
    _bytes.addAll(byteData.buffer.asUint8List());
  }

  void write(List<int> data) {
    _bytes.addAll(data);
  }

  Uint8List toBytes() {
    return Uint8List.fromList(_bytes);
  }
}

abstract class LedgerOperation<T> {
  Future<T> execute(Transport transport);

  void checkStatus(Uint8List response, [int successCode = StatusCodes.ok]) {
    if (response.length < 2) {
      throw TransportException(
          'Response is too short', 'InvalidResponseLength');
    }

    final sw =
        response.buffer.asByteData().getUint16(response.length - 2, Endian.big);

    if (sw != successCode) {
      throw TransportStatusError(sw);
    }
  }
}
