import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Thông tin một loại biển báo (43 lớp của mô hình).
class SignInfo {
  final int id;
  final String name;
  final String code;
  final String group;
  final String meaning;

  const SignInfo({required this.id, required this.name, required this.code, required this.group, required this.meaning});

  String get asset => 'assets/signs/$id.png';

  factory SignInfo.fromJson(Map<String, dynamic> j) => SignInfo(
        id: j['id'] as int,
        name: j['name'] as String,
        code: j['code'] as String,
        group: j['group'] as String,
        meaning: j['meaning'] as String,
      );
}

class SignDb {
  static List<SignInfo>? _all;

  static Future<List<SignInfo>> load() async {
    if (_all != null) return _all!;
    final text = await rootBundle.loadString('assets/signs.json');
    final list = (jsonDecode(text) as List).cast<Map<String, dynamic>>();
    _all = list.map(SignInfo.fromJson).toList();
    return _all!;
  }

  static SignInfo byId(int id) => _all![id];
}
