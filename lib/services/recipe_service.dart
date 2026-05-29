import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';
import '../config/app_config.dart';

final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService();
});

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'recipes';

  Future<List<RecipeModel>> searchRecipes(String query,
      {int page = 0}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(AppConfig.pageSize)
          .get();

      return snapshot.docs
          .map((doc) => RecipeModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<RecipeModel?> getRecipeById(String id) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return RecipeModel.fromJson(doc.data()!);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> saveRecipe(RecipeModel recipe) async {
    await _firestore
        .collection(_collection)
        .doc(recipe.recipeId)
        .set(recipe.toJson());
  }

  Future<List<RecipeModel>> getPopularRecipes() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('view_count', descending: true)
          .limit(AppConfig.pageSize)
          .get();

      return snapshot.docs
          .map((doc) => RecipeModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<RecipeModel>> getRecipesByCuisine(String cuisine) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('cuisine', isEqualTo: cuisine)
          .limit(AppConfig.pageSize)
          .get();

      return snapshot.docs
          .map((doc) => RecipeModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
