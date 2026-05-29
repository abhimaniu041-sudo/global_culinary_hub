import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

final geminiProviderProvider = Provider<GeminiProvider>((ref) {
  return GeminiProvider();
});

class GeminiProvider {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.geminiBaseUrl,
    connectTimeout:
        const Duration(milliseconds: AppConfig.connectionTimeout),
    receiveTimeout:
        const Duration(milliseconds: AppConfig.receiveTimeout),
  ));

  Future<String?> generate(String prompt) async {
    const storage = FlutterSecureStorage();
    final apiKey = await storage.read(key: 'GEMINI_API_KEY');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not found');
    }

    final response = await _dio.post(
      '/models/gemini-1.5-flash:generateContent?key=$apiKey',
      data: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String?;
        }
      }
    }
    throw Exception('Gemini: Invalid response');
  }
}
