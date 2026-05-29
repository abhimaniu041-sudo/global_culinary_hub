import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

final openaiProviderProvider = Provider<OpenAiProvider>((ref) {
  return OpenAiProvider();
});

class OpenAiProvider {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.openaiBaseUrl,
    connectTimeout:
        const Duration(milliseconds: AppConfig.connectionTimeout),
    receiveTimeout:
        const Duration(milliseconds: AppConfig.receiveTimeout),
  ));

  Future<String?> generate(String prompt) async {
    const storage = FlutterSecureStorage();
    final apiKey = await storage.read(key: 'OPENAI_API_KEY');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not found');
    }

    _dio.options.headers['Authorization'] = 'Bearer $apiKey';

    final response = await _dio.post(
      '/chat/completions',
      data: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 2048,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        return message?['content'] as String?;
      }
    }
    throw Exception('OpenAI: Invalid response');
  }
}
