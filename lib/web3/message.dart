import 'dart:convert';

import 'package:zilpay/src/rust/models/connection.dart';

class ZilPayWeb3Message {
  final String type;
  final Map<String, dynamic> payload;
  final String uuid;
  final String? icon;
  final String? title;
  final String? description;
  final ColorsInfo? colors;

  ZilPayWeb3Message({
    required this.type,
    required this.payload,
    required this.uuid,
    this.icon,
    this.title,
    this.description,
    this.colors,
  });

  factory ZilPayWeb3Message.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final payload = json['payload'] as Map<String, dynamic>? ?? {};
    String uuid = json['uuid'] ?? "";
    String icon = json['icon'] ?? "";
    String title = json['title'] ?? "";
    String description = json['description'] ?? "";

    ColorsInfo? colors;
    if (json['colors'] != null) {
      final colorsJson = json['colors'] as Map<String, dynamic>;
      colors = ColorsInfo(
        primary: colorsJson['primary'],
        secondary: colorsJson['secondary'],
        background: colorsJson['background'],
        text: colorsJson['text'],
      );
    }

    if (type == null) {
      throw FormatException('Invalid or unknown message type: $type');
    }

    return ZilPayWeb3Message(
      type: type,
      payload: payload,
      uuid: uuid,
      icon: icon,
      title: title,
      description: description,
      colors: colors,
    );
  }

  String payloadToJsonString() {
    return jsonEncode(payload);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'payload': payload,
      'uuid': uuid,
      'icon': icon,
      'title': title,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'ZilPayMessage(type: $type, payload: $payload uuid: $uuid, icon: $icon, title: $title)';
  }
}
