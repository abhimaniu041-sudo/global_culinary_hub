import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../ai/ai_orchestrator.dart';
import '../models/recipe_model.dart';

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService(ref);
});

class ImageAnalysisResult {
  final List<String> detectedIngredients;
  final List<String> detectedFoodItems;
  final String? ocrText;
  final List<RecipeModel> suggestedRecipes;
  final NutritionModel? estimatedNutrition;

  ImageAnalysisResult({
    required this.detectedIngredients,
    required this.detectedFoodItems,
    this.ocrText,
    required this.suggestedRecipes,
    this.estimatedNutrition,
  });
}

class ImageService {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ImageService(this._ref);

  Future<File?> pickImageFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  Future<File?> pickImageFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  Future<File> compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return file;

    final compressed = img.encodeJpg(decoded, quality: 75);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressed);
    return tempFile;
  }

  Future<String> uploadImage(File file, String userId) async {
    final compressed = await compressImage(file);
    final ref = _storage.ref(
        'food_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(compressed);
    return await ref.getDownloadURL();
  }

  Future<ImageAnalysisResult> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final orchestrator = _ref.read(aiOrchestratorProvider);
    final prompt = '''
Analyze this food image and respond ONLY with valid JSON:
{
  "detected_ingredients": ["ingredient1", "ingredient2"],
  "detected_food_items": ["food1", "food2"],
  "ocr_text": "any text visible in image",
  "suggested_recipe_names": ["recipe1", "recipe2"],
  "estimated_nutrition": {
    "calories": "300 kcal",
    "protein": "20g",
    "carbs": "35g",
    "fat": "8g"
  }
}
Image (base64): data:image/jpeg;base64,${base64Image.substring(0, 100)}...
''';

    try {
      final response = await orchestrator.generateText(prompt);
      final start = response.indexOf('{');
      final end = response.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final jsonStr = response.substring(start, end + 1);
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;

        return ImageAnalysisResult(
          detectedIngredients:
              List<String>.from(data['detected_ingredients'] as List? ?? []),
          detectedFoodItems:
              List<String>.from(data['detected_food_items'] as List? ?? []),
          ocrText: data['ocr_text'] as String?,
          suggestedRecipes: [],
          estimatedNutrition: data['estimated_nutrition'] != null
              ? NutritionModel.fromJson(
                  data['estimated_nutrition'] as Map<String, dynamic>)
              : null,
        );
      }
    } catch (e) {
      // Return empty result on error
    }

    return ImageAnalysisResult(
      detectedIngredients: [],
      detectedFoodItems: [],
      suggestedRecipes: [],
    );
  }
}
