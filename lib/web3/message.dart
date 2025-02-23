import 'dart:convert';

class ZilPayWeb3Message {
  final String type;
  final Map<String, dynamic> payload;
  final String uuid;

  ZilPayWeb3Message({
    required this.type,
    required this.payload,
    required this.uuid,
  });

  factory ZilPayWeb3Message.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final uuid = json['uuid'] ?? "";
    final payload = json['payload'] as Map<String, dynamic>? ?? {};

    if (type == null) {
      throw FormatException('Invalid or unknown message type: $type');
    }

    return ZilPayWeb3Message(type: type, payload: payload, uuid: uuid);
  }

  String payloadToJsonString() {
    return jsonEncode(payload);
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'payload': payload, 'uuid': uuid};
  }

  @override
  String toString() {
    return 'ZilPayMessage(type: $type, payload: $payload uuid: $uuid)';
  }
}
