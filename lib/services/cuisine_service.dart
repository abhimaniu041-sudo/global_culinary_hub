import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_orchestrator.dart';
import 'dart:convert';

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

  CuisineDish({
    required this.name,
    required this.originalName,
    required this.description,
    required this.history,
    required this.prepTime,
    required this.difficulty,
  });

  factory CuisineDish.fromJson(Map<String, dynamic> json) {
    return CuisineDish(
      name: json['name'] as String? ?? '',
      originalName: json['original_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      history: json['history'] as String? ?? '',
      prepTime: json['prep_time'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Medium',
    );
  }
}

class CuisineService {
  final Ref _ref;

  CuisineService(this._ref);

  Future<List<CuisineDish>> getCuisineDishes(String cuisineName) async {
    final orchestrator = _ref.read(aiOrchestratorProvider);
    final prompt = '''
List 12 most famous and authentic dishes from $cuisineName cuisine.
Respond ONLY with valid JSON array:
[
  {
    "name": "English Name",
    "original_name": "Native Language Name",
    "description": "Brief 1-2 sentence description",
    "history": "Brief history of this dish in 2-3 sentences",
    "prep_time": "30 minutes",
    "difficulty": "Easy"
  }
]
No extra text outside JSON.
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
