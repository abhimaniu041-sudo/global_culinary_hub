// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipeModelAdapter extends TypeAdapter<RecipeModel> {
  @override
  final int typeId = 0;

  @override
  RecipeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeModel(
      recipeId: fields[0] as String,
      name: fields[1] as String,
      cuisine: fields[2] as String,
      history: fields[3] as String,
      ingredients: (fields[4] as List).cast<String>(),
      instructions: (fields[5] as List).cast<String>(),
      prepTime: fields[6] as String,
      difficulty: fields[7] as String,
      servings: fields[8] as String,
      suggestedSubstitutions: (fields[9] as List).cast<String>(),
      nutrition: fields[10] as NutritionModel,
      imageUrl: fields[11] as String?,
      createdAt: fields[12] as DateTime,
      isFavorite: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.recipeId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.cuisine)
      ..writeByte(3)
      ..write(obj.history)
      ..writeByte(4)
      ..write(obj.ingredients)
      ..writeByte(5)
      ..write(obj.instructions)
      ..writeByte(6)
      ..write(obj.prepTime)
      ..writeByte(7)
      ..write(obj.difficulty)
      ..writeByte(8)
      ..write(obj.servings)
      ..writeByte(9)
      ..write(obj.suggestedSubstitutions)
      ..writeByte(10)
      ..write(obj.nutrition)
      ..writeByte(11)
      ..write(obj.imageUrl)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.isFavorite);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class NutritionModelAdapter extends TypeAdapter<NutritionModel> {
  @override
  final int typeId = 1;

  @override
  NutritionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionModel(
      calories: fields[0] as String,
      protein: fields[1] as String,
      carbs: fields[2] as String,
      fat: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.calories)
      ..writeByte(1)
      ..write(obj.protein)
      ..writeByte(2)
      ..write(obj.carbs)
      ..writeByte(3)
      ..write(obj.fat);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
