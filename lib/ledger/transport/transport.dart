import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:bearby/ledger/models/device_model.dart';
import 'package:bearby/ledger/transport/exceptions.dart';

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

    if (response.length < 2) {
      throw TransportException(
        'Response is too short',
        'InvalidResponseLength',
      );
    }

    final sw =
        (response[response.length - 2] << 8) | response[response.length - 1];

    debugPrint("Status code: 0x${sw.toRadixString(16)}");

    if (sw != 0x9000) {
      if (statusCodeChecker != null) {
        final exception = statusCodeChecker(sw);
        if (exception != null) {
          throw exception;
        }
      }
      throw TransportStatusError(sw, 'Status code: 0x${sw.toRadixString(16)}');
    }

    return response.sublist(0, response.length - 2);
  }
}
