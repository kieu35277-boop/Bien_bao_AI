import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  final DateTime time;
  final int signId;
  final double prob;
  final double inferenceMs;
  final bool confident;

  /// Người thử đánh dấu: true = app nhận diện đúng, false = sai, null = chưa đánh dấu.
  bool? correct;

  HistoryItem(this.time, this.signId, this.prob, this.inferenceMs, this.confident, {this.correct});

  Map<String, dynamic> toJson() =>
      {'t': time.toIso8601String(), 'id': signId, 'p': prob, 'ms': inferenceMs, 'ok': confident, 'c': correct};

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(DateTime.parse(j['t'] as String), j['id'] as int,
      (j['p'] as num).toDouble(), (j['ms'] as num).toDouble(), j['ok'] as bool,
      correct: j['c'] as bool?);
}

class HistoryStore {
  static const _key = 'history_v1';

  static Future<List<HistoryItem>> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_key) ?? [];
    return raw.map((s) => HistoryItem.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  static Future<void> add(HistoryItem item) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_key) ?? [];
    raw.insert(0, jsonEncode(item.toJson()));
    if (raw.length > 500) raw.removeRange(500, raw.length);
    await sp.setStringList(_key, raw);
  }

  /// Ghi lại toàn bộ danh sách (dùng sau khi đánh dấu đúng/sai).
  static Future<void> saveAll(List<HistoryItem> items) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_key, items.map((e) => jsonEncode(e.toJson())).toList());
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
