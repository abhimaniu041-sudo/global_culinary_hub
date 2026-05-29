import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

class FirebaseService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 30),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    await _remoteConfig.setDefaults({
      'gemini_api_key': '',
      'openai_api_key': '',
      'claude_api_key': '',
      'grok_api_key': '',
      'deepseek_api_key': '',
      'mistral_api_key': '',
      'huggingface_api_key': '',
    });

    await _remoteConfig.fetchAndActivate();
    await _syncApiKeys();
  }

  Future<void> _syncApiKeys() async {
    final keys = {
      'GEMINI_API_KEY': _remoteConfig.getString('gemini_api_key'),
      'OPENAI_API_KEY': _remoteConfig.getString('openai_api_key'),
      'CLAUDE_API_KEY': _remoteConfig.getString('claude_api_key'),
      'GROK_API_KEY': _remoteConfig.getString('grok_api_key'),
      'DEEPSEEK_API_KEY': _remoteConfig.getString('deepseek_api_key'),
      'MISTRAL_API_KEY': _remoteConfig.getString('mistral_api_key'),
      'HUGGINGFACE_API_KEY': _remoteConfig.getString('huggingface_api_key'),
    };

    for (final entry in keys.entries) {
      if (entry.value.isNotEmpty) {
        await _secureStorage.write(key: entry.key, value: entry.value);
      }
    }
  }

  Future<void> refreshConfig() async {
    await _remoteConfig.fetchAndActivate();
    await _syncApiKeys();
  }
}
