import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

final claudeProviderProvider = Provider<ClaudeProvider>((ref) {
  return ClaudeProvider();
});

class ClaudeProvider {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.claudeBaseUrl,
    connectTimeout:
        const Duration(milliseconds: AppConfig.connectionTimeout),
    receiveTimeout:
        const Duration(milliseconds: AppConfig.receiveTimeout),
  ));

  Future<String?> generate(String prompt) async {
    const storage = FlutterSecureStorage();
    final apiKey = await storage.read(key: 'CLAUDE_API_KEY');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Claude API key not found');
    }

    _dio.options.headers['x-api-key'] = apiKey;
    _dio.options.headers['anthropic-version'] = '2023-06-01';

    final response = await _dio.post(
      '/messages',
      data: jsonEncode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 2048,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final content = data['content'] as List?;
      if (content != null && content.isNotEmpty) {
        return content[0]['text'] as String?;
      }
    }
    throw Exception('Claude: Invalid response');
  }
}
