import 'package:hive/hive.dart';

part 'recipe_model.g.dart';

@HiveType(typeId: 0)
class RecipeModel extends HiveObject {
  @HiveField(0)
  final String recipeId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String cuisine;

  @HiveField(3)
  final String history;

  @HiveField(4)
  final List<String> ingredients;

  @HiveField(5)
  final List<String> instructions;

  @HiveField(6)
  final String prepTime;

  @HiveField(7)
  final String difficulty;

  @HiveField(8)
  final String servings;

  @HiveField(9)
  final List<String> suggestedSubstitutions;

  @HiveField(10)
  final NutritionModel nutrition;

  @HiveField(11)
  final String? imageUrl;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  bool isFavorite;

  RecipeModel({
    required this.recipeId,
    required this.name,
    required this.cuisine,
    required this.history,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.difficulty,
    required this.servings,
    required this.suggestedSubstitutions,
    required this.nutrition,
    this.imageUrl,
    required this.createdAt,
    this.isFavorite = false,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      recipeId: json['recipe_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      history: json['history'] as String? ?? '',
      ingredients: List<String>.from(json['ingredients'] as List? ?? []),
      instructions: List<String>.from(json['instructions'] as List? ?? []),
      prepTime: json['prep_time'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Medium',
      servings: json['servings'] as String? ?? '',
      suggestedSubstitutions: List<String>.from(
          json['suggested_substitutions'] as List? ?? []),
      nutrition: NutritionModel.fromJson(
          json['nutrition'] as Map<String, dynamic>? ?? {}),
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipe_id': recipeId,
      'name': name,
      'cuisine': cuisine,
      'history': history,
      'ingredients': ingredients,
      'instructions': instructions,
      'prep_time': prepTime,
      'difficulty': difficulty,
      'servings': servings,
      'suggested_substitutions': suggestedSubstitutions,
      'nutrition': nutrition.toJson(),
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'is_favorite': isFavorite,
    };
  }

  RecipeModel copyWith({
    String? recipeId,
    String? name,
    String? cuisine,
    String? history,
    List<String>? ingredients,
    List<String>? instructions,
    String? prepTime,
    String? difficulty,
    String? servings,
    List<String>? suggestedSubstitutions,
    NutritionModel? nutrition,
    String? imageUrl,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return RecipeModel(
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      history: history ?? this.history,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTime: prepTime ?? this.prepTime,
      difficulty: difficulty ?? this.difficulty,
      servings: servings ?? this.servings,
      suggestedSubstitutions:
          suggestedSubstitutions ?? this.suggestedSubstitutions,
      nutrition: nutrition ?? this.nutrition,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

@HiveType(typeId: 1)
class NutritionModel extends HiveObject {
  @HiveField(0)
  final String calories;

  @HiveField(1)
  final String protein;

  @HiveField(2)
  final String carbs;

  @HiveField(3)
  final String fat;

  NutritionModel({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionModel.fromJson(Map<String, dynamic> json) {
    return NutritionModel(
      calories: json['calories'] as String? ?? '0',
      protein: json['protein'] as String? ?? '0g',
      carbs: json['carbs'] as String? ?? '0g',
      fat: json['fat'] as String? ?? '0g',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
