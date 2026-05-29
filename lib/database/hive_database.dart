import 'package:hive_flutter/hive_flutter.dart';
import '../models/recipe_model.dart';

class HiveDatabase {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(RecipeModelAdapter());
    Hive.registerAdapter(NutritionModelAdapter());

    await Hive.openBox<RecipeModel>('favorites');
    await Hive.openBox<RecipeModel>('history');
    await Hive.openBox<RecipeModel>('offline_recipes');
    await Hive.openBox('ai_cache');
    await Hive.openBox('settings');
  }

  static Box<RecipeModel> get favoritesBox =>
      Hive.box<RecipeModel>('favorites');

  static Box<RecipeModel> get historyBox =>
      Hive.box<RecipeModel>('history');

  static Box<RecipeModel> get offlineRecipesBox =>
      Hive.box<RecipeModel>('offline_recipes');

  static Box get settingsBox => Hive.box('settings');

  static Future<void> addToFavorites(RecipeModel recipe) async {
    final box = favoritesBox;
    await box.put(recipe.recipeId, recipe);
  }

  static Future<void> removeFromFavorites(String recipeId) async {
    final box = favoritesBox;
    await box.delete(recipeId);
  }

  static bool isFavorite(String recipeId) {
    return favoritesBox.containsKey(recipeId);
  }

  static Future<void> addToHistory(RecipeModel recipe) async {
    final box = historyBox;
    if (box.length >= 100) {
      final firstKey = box.keys.first;
      await box.delete(firstKey);
    }
    await box.put(recipe.recipeId, recipe);
  }

  static List<RecipeModel> getFavorites() {
    return favoritesBox.values.toList().reversed.toList();
  }

  static List<RecipeModel> getHistory() {
    return historyBox.values.toList().reversed.toList();
  }
}
