import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_orchestrator.dart';

final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService(ref);
});

class TranslationService {
  final Ref _ref;

  TranslationService(this._ref);

  Future<String> translateText(String text, String targetLanguage) async {
    final orchestrator = _ref.read(aiOrchestratorProvider);
    final prompt = '''
Translate the following text to $targetLanguage.
Return ONLY the translated text, nothing else.
Format: "Translated text (Original text)"

Text to translate: "$text"
''';

    try {
      return await orchestrator.generateText(prompt);
    } catch (e) {
      return text;
    }
  }

  Future<String> detectLanguage(String text) async {
    final orchestrator = _ref.read(aiOrchestratorProvider);
    final prompt = '''
Detect the language of this text. Return ONLY the ISO 639-1 language code (e.g., "en", "hi", "es").
Text: "$text"
''';

    try {
      final result = await orchestrator.generateText(prompt);
      return result.trim().toLowerCase().substring(0, 2);
    } catch (e) {
      return 'en';
    }
  }
}
