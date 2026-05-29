import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';
import '../ai/ai_orchestrator.dart';
import '../database/hive_database.dart';

final recipeSearchQueryProvider = StateProvider<String>((ref) => '');

final recipeGenerationProvider =
    StateNotifierProvider<RecipeGenerationNotifier,
        AsyncValue<RecipeModel?>>((ref) {
  return RecipeGenerationNotifier(ref);
});

class RecipeGenerationNotifier
    extends StateNotifier<AsyncValue<RecipeModel?>> {
  final Ref _ref;

  RecipeGenerationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> generateRecipe(String query,
      {String language = 'en'}) async {
    state = const AsyncValue.loading();
    try {
      final orchestrator = _ref.read(aiOrchestratorProvider);
      final recipe =
          await orchestrator.generateRecipe(query, language: language);
      if (recipe != null) {
        await HiveDatabase.addToHistory(recipe);
      }
      state = AsyncValue.data(recipe);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<RecipeModel>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<RecipeModel>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  void _loadFavorites() {
    state = HiveDatabase.getFavorites();
  }

  Future<void> toggleFavorite(RecipeModel recipe) async {
    if (HiveDatabase.isFavorite(recipe.recipeId)) {
      await HiveDatabase.removeFromFavorites(recipe.recipeId);
    } else {
      await HiveDatabase.addToFavorites(recipe);
    }
    state = HiveDatabase.getFavorites();
  }

  bool isFavorite(String recipeId) {
    return HiveDatabase.isFavorite(recipeId);
  }
}

final historyProvider = Provider<List<RecipeModel>>((ref) {
  return HiveDatabase.getHistory();
});
