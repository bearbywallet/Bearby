import 'dart:convert';
import 'dart:typed_data';

import 'package:ledger_flutter/ledger_flutter.dart';

AppData decodeAppData(Uint8List data, Counter offset) {
  try {
    offset.value++;

    AppData appInfo = AppData();

    ByteData flagsBytes =
        ByteData.sublistView(data, offset.value, offset.value + 4);
    appInfo.flags = flagsBytes.getUint32(0, Endian.big);
    offset.value += 4;

    appInfo.hashCodeData
        .setAll(0, data.sublist(offset.value, offset.value + 32));
    offset.value += 32;

    appInfo.hash.setAll(0, data.sublist(offset.value, offset.value + 32));
    offset.value += 32;

    int nameLen = data[offset.value];
    offset.value++;

    appInfo.name =
        utf8.decode(data.sublist(offset.value, offset.value + nameLen));
    offset.value += nameLen;

    return appInfo;
  } catch (e) {
    throw ApduError('Failed to decode AppData: ${e.toString()}');
  }
}

class ApduError implements Exception {
  final String message;
  ApduError(this.message);

  @override
  String toString() => 'ApduError: $message';
}

class AppData {
  int flags = 0;
  Uint8List hashCodeData = Uint8List(32);
  Uint8List hash = Uint8List(32);
  String name = '';

  AppData();

  @override
  int get hashCode {
    return Object.hash(
      flags,
      Object.hashAll(hashCodeData),
      Object.hashAll(hash),
      name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppData &&
        other.flags == flags &&
        listsEqual(other.hashCodeData, hashCodeData) &&
        listsEqual(other.hash, hash) &&
        other.name == name;
  }

  AppData clone() {
    AppData cloned = AppData();
    cloned.flags = flags;
    cloned.hashCodeData.setAll(0, hashCodeData);
    cloned.hash.setAll(0, hash);
    cloned.name = name;
    return cloned;
  }

  bool listsEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'AppData(flags: $flags, hashCodeData: $hashCodeData, hash: $hash, name: $name)';
  }
}

class Counter {
  int value;
  Counter(this.value);
}

class GetInstalledAppsOperation extends LedgerOperation<AppData> {
  final int ins;

  GetInstalledAppsOperation(this.ins);

  @override
  Future<AppData> read(ByteDataReader reader) async {
    final offset = Counter(1);
    final data = reader.read(reader.remainingLength);

    print("data: $data");

    final AppData v = decodeAppData(data, offset);

    return v;
  }

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(0xe0);
    writer.writeUint8(ins);
    writer.writeUint8(0x00);
    writer.writeUint8(0x00);
    writer.writeUint8(0x00);

    return [writer.toBytes()];
  }
}
