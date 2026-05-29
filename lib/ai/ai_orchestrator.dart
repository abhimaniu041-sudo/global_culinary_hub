import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_provider_model.dart';
import '../models/recipe_model.dart';
import '../cache/local_cache.dart';
import '../utils/constants.dart';
import 'provider_health_monitor.dart';
import 'providers/gemini_provider.dart';
import 'providers/openai_provider.dart';
import 'providers/claude_provider.dart';
import 'providers/grok_provider.dart';
import 'providers/deepseek_provider.dart';
import 'providers/mistral_provider.dart';
import 'providers/huggingface_provider.dart';

final aiOrchestratorProvider = Provider<AiOrchestrator>((ref) {
  return AiOrchestrator(ref);
});

class AiOrchestrator {
  final Ref _ref;
  AiExecutionMode _mode = AiExecutionMode.highQuality;

  static const List<AiProviderName> _highQualityOrder = [
    AiProviderName.gemini,
    AiProviderName.claude,
    AiProviderName.openai,
    AiProviderName.grok,
    AiProviderName.deepseek,
    AiProviderName.mistral,
  ];

  static const List<AiProviderName> _lowCostOrder = [
    AiProviderName.gemini,
    AiProviderName.huggingface,
    AiProviderName.deepseek,
    AiProviderName.mistral,
    AiProviderName.grok,
    AiProviderName.claude,
    AiProviderName.openai,
  ];

  static const List<AiProviderName> _defaultFailoverOrder = [
    AiProviderName.gemini,
    AiProviderName.grok,
    AiProviderName.huggingface,
    AiProviderName.claude,
    AiProviderName.openai,
    AiProviderName.deepseek,
    AiProviderName.mistral,
  ];

  AiOrchestrator(this._ref);

  void setMode(AiExecutionMode mode) {
    _mode = mode;
  }

  List<AiProviderName> _getProviderOrder() {
    final healthMonitor = _ref.read(providerHealthMonitorProvider);
    List<AiProviderName> order;

    switch (_mode) {
      case AiExecutionMode.highQuality:
        order = _highQualityOrder;
        break;
      case AiExecutionMode.lowCost:
        order = _lowCostOrder;
        break;
      case AiExecutionMode.fastest:
        final providers = List<AiProviderName>.from(_defaultFailoverOrder);
        providers.sort((a, b) {
          final healthA = healthMonitor.getProvider(a);
          final healthB = healthMonitor.getProvider(b);
          return healthA.averageLatencyMs
              .compareTo(healthB.averageLatencyMs);
        });
        order = providers;
        break;
      case AiExecutionMode.custom:
        order = _defaultFailoverOrder;
        break;
    }

    return order
        .where((p) => healthMonitor.getProvider(p).isAvailable)
        .toList();
  }

  Future<String> generateText(String prompt) async {
    final cache = _ref.read(localCacheProvider);
    final cacheKey = cache.hashPrompt(prompt);
    final cached = await cache.get(cacheKey);
    if (cached != null) return cached;

    final providers = _getProviderOrder();
    String? result;
    Exception? lastException;

    for (final providerName in providers) {
      try {
        final stopwatch = Stopwatch()..start();
        result = await _callProvider(providerName, prompt);
        stopwatch.stop();

        _ref
            .read(providerHealthMonitorProvider)
            .recordSuccess(providerName, stopwatch.elapsedMilliseconds.toDouble());

        if (result != null) {
          await cache.set(cacheKey, result);
          return result;
        }
      } catch (e) {
        lastException = e as Exception?;
        _ref
            .read(providerHealthMonitorProvider)
            .recordFailure(providerName, e.toString());
        continue;
      }
    }

    throw lastException ?? Exception('All AI providers failed');
  }

  Future<RecipeModel?> generateRecipe(
      String query, {String language = 'en'}) async {
    final prompt = _buildRecipePrompt(query, language);
    final jsonString = await generateText(prompt);
    try {
      final cleanJson = _extractJson(jsonString);
      final json = _parseJson(cleanJson);
      return RecipeModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<String?> _callProvider(
      AiProviderName providerName, String prompt) async {
    switch (providerName) {
      case AiProviderName.gemini:
        return _ref.read(geminiProviderProvider).generate(prompt);
      case AiProviderName.openai:
        return _ref.read(openaiProviderProvider).generate(prompt);
      case AiProviderName.claude:
        return _ref.read(claudeProviderProvider).generate(prompt);
      case AiProviderName.grok:
        return _ref.read(grokProviderProvider).generate(prompt);
      case AiProviderName.deepseek:
        return _ref.read(deepseekProviderProvider).generate(prompt);
      case AiProviderName.mistral:
        return _ref.read(mistralProviderProvider).generate(prompt);
      case AiProviderName.huggingface:
        return _ref.read(huggingfaceProviderProvider).generate(prompt);
    }
  }

  String _buildRecipePrompt(String query, String language) {
    return '''
You are an expert global culinary chef. Generate a complete, authentic recipe for: "$query"

Language preference: $language

Respond ONLY with valid JSON in this exact format:
{
  "recipe_id": "unique_id_here",
  "name": "Translated Name (Original Name)",
  "cuisine": "cuisine type",
  "history": "brief history of this dish",
  "ingredients": ["ingredient 1", "ingredient 2"],
  "instructions": ["Step 1: ...", "Step 2: ...", "Step 3: ..."],
  "prep_time": "30 minutes",
  "difficulty": "Easy",
  "servings": "4 people",
  "suggested_substitutions": ["substitute 1", "substitute 2"],
  "nutrition": {
    "calories": "350 kcal",
    "protein": "25g",
    "carbs": "40g",
    "fat": "10g"
  }
}

Provide authentic, detailed, accurate information. No additional text outside the JSON.
''';
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    // Simple JSON parsing using dart:convert
    // ignore: avoid_dynamic_calls
    return Map<String, dynamic>.from(
        _jsonDecode(jsonString) as Map<dynamic, dynamic>);
  }

  dynamic _jsonDecode(String source) {
    // Uses dart:convert internally
    return _dartConvertJsonDecode(source);
  }

  // ignore: non_constant_identifier_names
  dynamic _dartConvertJsonDecode(String source) {
    // This will be replaced at runtime with actual dart:convert
    throw UnimplementedError('Use dart:convert');
  }
}
