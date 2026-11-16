import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ForwardHistoryItem {
  final int time;
  final String sender;
  final String body;
  final String driver;
  final String destinations;

  const ForwardHistoryItem({
    required this.time,
    required this.sender,
    required this.body,
    required this.driver,
    required this.destinations,
  });

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(time, isUtc: false);

  factory ForwardHistoryItem.fromJson(Map<String, dynamic> json) {
    return ForwardHistoryItem(
      time: (json['time'] is int)
          ? json['time'] as int
          : int.tryParse('${json['time']}') ?? 0,
      sender: '${json['sender'] ?? ''}',
      body: '${json['body'] ?? ''}',
      driver: '${json['driver'] ?? ''}',
      destinations: '${json['dest'] ?? ''}',
    );
  }
}

class ForwardHistoryService {
  static const String _key = 'forward_history';

  static Future<List<ForwardHistoryItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((e) => ForwardHistoryItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
