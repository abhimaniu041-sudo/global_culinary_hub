import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';
import '../database/hive_database.dart';
import '../utils/helpers.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref);
});

class RecipeRepository {
  final Ref _ref;

  RecipeRepository(this._ref);

  Future<List<RecipeModel>> searchRecipes(String query) async {
    final isOnline = await AppHelpers.isOnline();

    if (!isOnline) {
      return _searchOffline(query);
    }

    try {
      final service = _ref.read(recipeServiceProvider);
      return await service.searchRecipes(query);
    } catch (e) {
      return _searchOffline(query);
    }
  }

  List<RecipeModel> _searchOffline(String query) {
    final offlineRecipes =
        HiveDatabase.offlineRecipesBox.values.toList();
    final queryLower = query.toLowerCase();
    return offlineRecipes
        .where((r) =>
            r.name.toLowerCase().contains(queryLower) ||
            r.cuisine.toLowerCase().contains(queryLower) ||
            r.ingredients
                .any((i) => i.toLowerCase().contains(queryLower)))
        .toList();
  }

  Future<RecipeModel?> getRecipeById(String id) async {
    final cached = HiveDatabase.offlineRecipesBox.get(id);
    if (cached != null) return cached;

    try {
      final service = _ref.read(recipeServiceProvider);
      final recipe = await service.getRecipeById(id);
      if (recipe != null) {
        await HiveDatabase.offlineRecipesBox.put(id, recipe);
      }
      return recipe;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveRecipeOffline(RecipeModel recipe) async {
    await HiveDatabase.offlineRecipesBox.put(recipe.recipeId, recipe);
  }
}
