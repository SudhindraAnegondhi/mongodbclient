import 'dart:convert';


class AppConfig {
  final String serverAddress;
  final String authSecret;
  final bool useTSL;
  AppConfig({
    this.serverAddress = 'localhost:8888',
    this.authSecret,
    this.useTSL = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'serverAddress': serverAddress,
      'authSecret': authSecret,
      'useTSL': useTSL,
    };
  }

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return AppConfig(
      serverAddress: map['serverAddress'],
      authSecret: map['authSecret'],
      useTSL: map['useTSL'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppConfig.fromJson(String source) =>
      AppConfig.fromMap(json.decode(source));
}
