import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/image_service.dart';
import '../../widgets/loading_widget.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  File? _selectedImage;
  ImageAnalysisResult? _analysisResult;
  bool _isAnalyzing = false;
  String? _errorMessage;

  Future<void> _pickFromCamera() async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.pickImageFromCamera();
    if (file != null) {
      setState(() {
        _selectedImage = file;
        _analysisResult = null;
      });
      await _analyzeImage(file);
    }
  }

  Future<void> _pickFromGallery() async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.pickImageFromGallery();
    if (file != null) {
      setState(() {
        _selectedImage = file;
        _analysisResult = null;
      });
      await _analyzeImage(file);
    }
  }

  Future<void> _analyzeImage(File file) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final imageService = ref.read(imageServiceProvider);
      final result = await imageService.analyzeImage(file);
      setState(() => _analysisResult = result);
    } catch (e) {
      setState(() => _errorMessage = 'Analysis failed. Please try again.');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'AI Food Scanner',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scan food to detect ingredients and get recipes',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Take or select a food photo',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          if (_isAnalyzing) ...[
            const SizedBox(height: 24),
            const LoadingWidget(message: 'AI is analyzing your food...'),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(_errorMessage!,
                style: TextStyle(color: colorScheme.error)),
          ],
          if (_analysisResult != null) ...[
            const SizedBox(height: 24),
            _AnalysisResultWidget(result: _analysisResult!),
          ],
        ],
      ),
    );
  }
}

class _AnalysisResultWidget extends StatelessWidget {
  final ImageAnalysisResult result;
  const _AnalysisResultWidget({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Results',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (result.detectedFoodItems.isNotEmpty) ...[
          const Text('Detected Food:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.detectedFoodItems
                .map((food) => Chip(
                      label: Text(food),
                      backgroundColor:
                          colorScheme.primaryContainer,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (result.detectedIngredients.isNotEmpty) ...[
          const Text('Detected Ingredients:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.detectedIngredients
                .map((ing) => Chip(
                      label: Text(ing),
                      backgroundColor:
                          colorScheme.secondaryContainer,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (result.estimatedNutrition != null) ...[
          const Text('Estimated Nutrition:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _NutChip('Calories', result.estimatedNutrition!.calories),
              _NutChip('Protein', result.estimatedNutrition!.protein),
              _NutChip('Carbs', result.estimatedNutrition!.carbs),
              _NutChip('Fat', result.estimatedNutrition!.fat),
            ],
          ),
          const SizedBox(height: 16),
        ],
        ElevatedButton.icon(
          onPressed: () {
            final query = result.detectedFoodItems.isNotEmpty
                ? result.detectedFoodItems.first
                : result.detectedIngredients.isNotEmpty
                    ? 'recipe with ${result.detectedIngredients.take(3).join(", ")}'
                    : 'recipe';
            context.go(
                '/generate?q=${Uri.encodeComponent(query)}');
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate Recipe'),
        ),
      ],
    );
  }
}

class _NutChip extends StatelessWidget {
  final String label;
  final String value;
  const _NutChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
