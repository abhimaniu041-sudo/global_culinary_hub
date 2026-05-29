import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';

final localCacheProvider = Provider<LocalCache>((ref) {
  return LocalCache();
});

class CacheEntry {
  final String key;
  final String value;
  final DateTime timestamp;
  final String provider;

  CacheEntry({
    required this.key,
    required this.value,
    required this.timestamp,
    required this.provider,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'timestamp': timestamp.toIso8601String(),
        'provider': provider,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        key: json['key'] as String,
        value: json['value'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        provider: json['provider'] as String? ?? 'unknown',
      );
}

class LocalCache {
  static const String _boxName = 'ai_cache';

  Future<Box> get _box async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  String hashPrompt(String prompt) {
    final bytes = utf8.encode(prompt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String?> get(String key) async {
    final box = await _box;
    final entryJson = box.get(key) as String?;
    if (entryJson == null) return null;

    try {
      final entry =
          CacheEntry.fromJson(jsonDecode(entryJson) as Map<String, dynamic>);
      final age =
          DateTime.now().difference(entry.timestamp).inHours;
      if (age > AppConfig.localCacheDurationHours) {
        await box.delete(key);
        return null;
      }
      return entry.value;
    } catch (e) {
      await box.delete(key);
      return null;
    }
  }

  Future<void> set(String key, String value,
      {String provider = 'unknown'}) async {
    final box = await _box;
    final entry = CacheEntry(
      key: key,
      value: value,
      timestamp: DateTime.now(),
      provider: provider,
    );

    if (box.length >= AppConfig.maxCacheEntries) {
      await _evictOldest(box);
    }

    await box.put(key, jsonEncode(entry.toJson()));
  }

  Future<void> _evictOldest(Box box) async {
    final keys = box.keys.toList();
    if (keys.isEmpty) return;
    await box.delete(keys.first);
  }

  Future<void> clear() async {
    final box = await _box;
    await box.clear();
  }

  Future<int> get size async {
    final box = await _box;
    return box.length;
  }
}
