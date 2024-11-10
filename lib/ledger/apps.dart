import 'dart:typed_data';
import 'package:ledger_flutter/ledger_flutter.dart';

class LedgerInstalledApp {
  final String name;
  final String version;

  LedgerInstalledApp({required this.name, required this.version});
}

class GetInstalledAppsOperation
    extends LedgerOperation<List<LedgerInstalledApp>> {
  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    // Manager CLA
    writer.writeUint8(0xB0);
    // Get App List INS
    writer.writeUint8(0x67);
    // P1: 0x00
    writer.writeUint8(0x00);
    // P2: 0x00
    writer.writeUint8(0x00);
    // No data needed for this command
    writer.writeUint8(0x00);

    return [writer.toBytes()];
  }

  @override
  Future<List<LedgerInstalledApp>> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);
    final apps = <LedgerInstalledApp>[];

    // Response format is TLV (Tag-Length-Value)
    var offset = 0;
    while (offset < response.length) {
      // Each entry starts with a tag byte
      final tag = response[offset];
      offset++;

      // Length of the value
      final length = response[offset];
      offset++;

      // Extract the value based on the tag
      if (tag == 0x01) {
        // Application name
        final name =
            String.fromCharCodes(response.sublist(offset, offset + length));

        // Move to version
        offset += length;
        offset++;
        final versionLength = response[offset];
        offset++;

        final version = String.fromCharCodes(
            response.sublist(offset, offset + versionLength));

        apps.add(LedgerInstalledApp(name: name, version: version));
        offset += versionLength;
      } else {
        // Skip unknown tags
        offset += length;
      }
    }

    return apps;
  }
}
