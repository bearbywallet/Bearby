import 'dart:convert';

class EIP712Type {
  final String name;
  final String type;

  EIP712Type({required this.name, required this.type});

  factory EIP712Type.fromJson(Map<String, dynamic> json) {
    print('EIP712Type.fromJson: json=$json');
    print(
        'EIP712Type.fromJson: name=${json['name']} (type: ${json['name'].runtimeType})');
    print(
        'EIP712Type.fromJson: type=${json['type']} (type: ${json['type'].runtimeType})');
    return EIP712Type(
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
    };
  }
}

class EIP712Domain {
  final String name;
  final String? version;
  final dynamic chainId;
  final String? verifyingContract;

  EIP712Domain({
    required this.name,
    this.version,
    required this.chainId,
    this.verifyingContract,
  });

  factory EIP712Domain.fromJson(Map<String, dynamic> json) {
    print('EIP712Domain.fromJson: json=$json');
    print(
        'EIP712Domain.fromJson: name=${json['name']} (type: ${json['name'].runtimeType})');
    print(
        'EIP712Domain.fromJson: version=${json['version']} (type: ${json['version'].runtimeType})');
    print(
        'EIP712Domain.fromJson: chainId=${json['chainId']} (type: ${json['chainId'].runtimeType})');
    print(
        'EIP712Domain.fromJson: verifyingContract=${json['verifyingContract']} (type: ${json['verifyingContract'].runtimeType})');
    return EIP712Domain(
      name: json['name'] as String,
      version: json['version'] as String?,
      chainId: json['chainId'],
      verifyingContract: json['verifyingContract'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {
      'name': name,
      'chainId': chainId,
    };
    if (version != null) {
      result['version'] = version;
    }
    if (verifyingContract != null) {
      result['verifyingContract'] = verifyingContract;
    }
    return result;
  }
}

class TypedDataEip712 {
  final Map<String, List<EIP712Type>> types;
  final String primaryType;
  final EIP712Domain domain;
  final Map<String, dynamic> message;

  TypedDataEip712({
    required this.types,
    required this.primaryType,
    required this.domain,
    required this.message,
  });

  factory TypedDataEip712.fromJson(Map<String, dynamic> json) {
    print('TypedDataEip712.fromJson: json=$json');
    print(
        'TypedDataEip712.fromJson: types=${json['types']} (type: ${json['types'].runtimeType})');
    print(
        'TypedDataEip712.fromJson: primaryType=${json['primaryType']} (type: ${json['primaryType'].runtimeType})');
    print(
        'TypedDataEip712.fromJson: domain=${json['domain']} (type: ${json['domain'].runtimeType})');
    print(
        'TypedDataEip712.fromJson: message=${json['message']} (type: ${json['message'].runtimeType})');

    final typesJson = json['types'] as Map<String, dynamic>;
    final types = typesJson.map((key, value) => MapEntry(
          key,
          (value as List)
              .map((e) => EIP712Type.fromJson(e as Map<String, dynamic>))
              .toList(),
        ));

    return TypedDataEip712(
      types: types,
      primaryType: json['primaryType'] as String,
      domain: EIP712Domain.fromJson(json['domain'] as Map<String, dynamic>),
      message: json['message'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'types': types.map((key, value) => MapEntry(
            key,
            value.map((type) => type.toJson()).toList(),
          )),
      'primaryType': primaryType,
      'domain': domain.toJson(),
      'message': message,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  static TypedDataEip712 fromJsonString(String jsonStr) {
    print('TypedDataEip712.fromJsonString: raw json string=$jsonStr');
    final decoded = jsonDecode(jsonStr);
    print(
        'TypedDataEip712.fromJsonString: decoded=$decoded (type: ${decoded.runtimeType})');
    return TypedDataEip712.fromJson(decoded as Map<String, dynamic>);
  }
}
