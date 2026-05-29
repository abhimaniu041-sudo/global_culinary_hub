import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

final cloudCacheProvider = Provider<CloudCache>((ref) {
  return CloudCache();
});

class CloudCache {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'ai_cache';

  Future<String?> get(String key) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(key).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      if (timestamp == null) return null;

      final age = DateTime.now().difference(timestamp).inHours;
      if (age > AppConfig.cloudCacheDurationHours) {
        await _firestore.collection(_collection).doc(key).delete();
        return null;
      }

      return data['value'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> set(String key, String value,
      {String provider = 'unknown'}) async {
    try {
      await _firestore.collection(_collection).doc(key).set({
        'key': key,
        'value': value,
        'provider': provider,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail cloud cache writes
    }
  }
}
