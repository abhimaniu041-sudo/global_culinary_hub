import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_orchestrator.dart';

final cuisineServiceProvider = Provider<CuisineService>((ref) {
  return CuisineService(ref);
});

class CuisineDish {
  final String name;
  final String originalName;
  final String description;
  final String history;
  final String prepTime;
  final String difficulty;
  final String imageQuery;

  CuisineDish({
    required this.name,
    required this.originalName,
    required this.description,
    required this.history,
    required this.prepTime,
    required this.difficulty,
    required this.imageQuery,
  });

  factory CuisineDish.fromJson(Map<String, dynamic> json) {
    return CuisineDish(
      name: json['name'] as String? ?? '',
      originalName: json['original_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      history: json['history'] as String? ?? '',
      prepTime: json['prep_time'] as String? ?? '30 min',
      difficulty: json['difficulty'] as String? ?? 'Medium',
      imageQuery: json['image_query'] as String? ?? json['name'] as String? ?? '',
    );
  }

  String get imageUrl =>
      'https://source.unsplash.com/400x300/?${Uri.encodeComponent(imageQuery)},food';
}

class CuisineService {
  final Ref _ref;

  CuisineService(this._ref);

  Future<List<CuisineDish>> getCuisineDishes(
      String cuisineName, {int page = 0}) async {
    final orchestrator = _ref.read(aiOrchestratorProvider);
    final offset = page * 20 + 1;
    final prompt = '''
List 20 authentic $cuisineName dishes (dishes $offset to ${offset + 19}).
Include well-known and lesser-known authentic dishes.
Respond ONLY with valid JSON array, no extra text:
[
  {
    "name": "English Name",
    "original_name": "Native script name",
    "description": "One sentence description of taste and texture",
    "history": "2 sentences about origin and cultural significance",
    "prep_time": "X minutes",
    "difficulty": "Easy",
    "image_query": "specific dish name for photo search"
  }
]
''';

    try {
      final response = await orchestrator.generateText(prompt);
      final start = response.indexOf('[');
      final end = response.lastIndexOf(']');
      if (start >= 0 && end > start) {
        final jsonStr = response.substring(start, end + 1);
        final list = jsonDecode(jsonStr) as List;
        return list
            .map((e) => CuisineDish.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }
}
