import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:zilpay/ledger/models/device_model.dart';
import 'package:zilpay/ledger/transport/exceptions.dart';

enum TransportEvent { unresponsive, responsive }

abstract class Transport {
  DeviceModel? get deviceModel;

  Stream<TransportEvent> get events;

  void setScrambleKey(String key);

  Future<Uint8List> exchange(Uint8List apdu);

  Future<void> close();

  Future<Uint8List> send(
    int cla,
    int ins,
    int p1,
    int p2,
    Uint8List data, [
    TransportStatusError? Function(int)? statusCodeChecker,
  ]) async {
    if (data.length > 255) {
      throw TransportException(
        'data.length exceed 255 bytes limit',
        'DataLengthTooBig',
      );
    }

    final apdu = Uint8List.fromList([cla, ins, p1, p2, data.length, ...data]);
    final response = await exchange(apdu);

    debugPrint("response: $response");
    if (response.length < 2) {
      throw TransportException(
        'Response is too short',
        'InvalidResponseLength',
      );
    }

    final sw =
        response.buffer.asByteData().getUint16(response.length - 2, Endian.big);

    if (statusCodeChecker != null) {
      final exception = statusCodeChecker(sw);

      if (exception != null) {
        throw exception;
      }
    }

    return response.sublist(0, response.length - 2);
  }
}
