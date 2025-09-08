import 'dart:typed_data';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';

class EthereumProvideERC20TokenOperation extends LedgerRawOperation<bool> {
  final String data;

  EthereumProvideERC20TokenOperation({required this.data});

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(0xe0);
    writer.writeUint8(0x0a);
    writer.writeUint8(0x00);
    writer.writeUint8(0x00);

    final buffer = _hexToBytes(data);
    writer.writeUint8(buffer.length);
    writer.write(buffer);

    return [writer.toBytes()];
  }

  @override
  Future<bool> read(ByteDataReader reader) async {
    return true;
  }

  Uint8List _hexToBytes(String hex) {
    final cleanHex = hex.startsWith('0x') ? hex.substring(2) : hex;
    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}

class EthereumSetPluginOperation extends LedgerRawOperation<bool> {
  final String data;

  EthereumSetPluginOperation({required this.data});

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(0xe0);
    writer.writeUint8(0x16);
    writer.writeUint8(0x00);
    writer.writeUint8(0x00);

    final buffer = _hexToBytes(data);
    writer.writeUint8(buffer.length);
    writer.write(buffer);

    return [writer.toBytes()];
  }

  @override
  Future<bool> read(ByteDataReader reader) async {
    return true;
  }

  Uint8List _hexToBytes(String hex) {
    final cleanHex = hex.startsWith('0x') ? hex.substring(2) : hex;
    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}

class EthereumSetExternalPluginOperation extends LedgerRawOperation<bool> {
  final String payload;
  final String signature;

  EthereumSetExternalPluginOperation({
    required this.payload,
    required this.signature,
  });

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(0xe0);
    writer.writeUint8(0x12);
    writer.writeUint8(0x00);
    writer.writeUint8(0x00);

    final payloadBuffer = _hexToBytes(payload);
    final signatureBuffer = _hexToBytes(signature);
    final combinedBuffer =
        Uint8List.fromList([...payloadBuffer, ...signatureBuffer]);

    writer.writeUint8(combinedBuffer.length);
    writer.write(combinedBuffer);

    return [writer.toBytes()];
  }

  @override
  Future<bool> read(ByteDataReader reader) async {
    return true;
  }

  Uint8List _hexToBytes(String hex) {
    final cleanHex = hex.startsWith('0x') ? hex.substring(2) : hex;
    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}

class EthereumProvideNFTInformationOperation extends LedgerRawOperation<bool> {
  final String data;

  EthereumProvideNFTInformationOperation({required this.data});

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(0xe0);
    writer.writeUint8(0x14);
    writer.writeUint8(0x00);
    writer.writeUint8(0x00);

    final buffer = _hexToBytes(data);
    writer.writeUint8(buffer.length);
    writer.write(buffer);

    return [writer.toBytes()];
  }

  @override
  Future<bool> read(ByteDataReader reader) async {
    return true;
  }

  Uint8List _hexToBytes(String hex) {
    final cleanHex = hex.startsWith('0x') ? hex.substring(2) : hex;
    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}

class EthereumProvideDomainNameOperation extends LedgerComplexOperation<bool> {
  final String data;

  const EthereumProvideDomainNameOperation({required this.data});

  @override
  Future<bool> invoke(LedgerSendFct send) async {
    const int cla = 0xe0;
    const int ins = 0x22;
    const int p1FirstChunk = 0x01;
    const int p1FollowingChunk = 0x00;
    const int p2 = 0x00;

    final buffer = _hexToBytes(data);
    final lengthBytes = _intToBytes(buffer.length, 2);
    final payload = Uint8List.fromList([...lengthBytes, ...buffer]);

    final maxChunkSize = 255;
    final chunks = <Uint8List>[];

    for (int i = 0; i < payload.length; i += maxChunkSize) {
      final end = (i + maxChunkSize < payload.length)
          ? i + maxChunkSize
          : payload.length;
      chunks.add(payload.sublist(i, end));
    }

    for (int i = 0; i < chunks.length; i++) {
      final isFirstChunk = i == 0;
      await send(
        LedgerSimpleOperation(
          cla: cla,
          ins: ins,
          p1: isFirstChunk ? p1FirstChunk : p1FollowingChunk,
          p2: p2,
          data: chunks[i],
          prependDataLength: true,
          debugName: 'Provide Domain Name Chunk ${i + 1}',
        ),
      );
    }

    return true;
  }

  Uint8List _hexToBytes(String hex) {
    final cleanHex = hex.startsWith('0x') ? hex.substring(2) : hex;
    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  List<int> _intToBytes(int value, int bytes) {
    final result = <int>[];
    for (int i = bytes - 1; i >= 0; i--) {
      result.add((value >> (i * 8)) & 0xff);
    }
    return result;
  }
}
