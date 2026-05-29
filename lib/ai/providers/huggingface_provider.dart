import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

final huggingfaceProviderProvider = Provider<HuggingFaceProvider>((ref) {
  return HuggingFaceProvider();
});

class HuggingFaceProvider {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.huggingfaceBaseUrl,
    connectTimeout:
        const Duration(milliseconds: AppConfig.connectionTimeout),
    receiveTimeout:
        const Duration(milliseconds: AppConfig.receiveTimeout),
  ));

  Future<String?> generate(String prompt) async {
    const storage = FlutterSecureStorage();
    final apiKey = await storage.read(key: 'HUGGINGFACE_API_KEY');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('HuggingFace API key not found');
    }

    _dio.options.headers['Authorization'] = 'Bearer $apiKey';

    final response = await _dio.post(
      '/mistralai/Mistral-7B-Instruct-v0.2',
      data: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'max_new_tokens': 1024,
          'temperature': 0.7,
          'return_full_text': false,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List && data.isNotEmpty) {
        return data[0]['generated_text'] as String?;
      }
    }
    throw Exception('HuggingFace: Invalid response');
  }
}
