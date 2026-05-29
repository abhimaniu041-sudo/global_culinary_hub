import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/loading_widget.dart';

class RecipeGenerateScreen extends ConsumerStatefulWidget {
  const RecipeGenerateScreen({super.key});

  @override
  ConsumerState<RecipeGenerateScreen> createState() =>
      _RecipeGenerateScreenState();
}

class _RecipeGenerateScreenState extends ConsumerState<RecipeGenerateScreen> {
  final _queryController = TextEditingController();
  String _selectedLanguage = 'en';

  final Map<String, String> _languages = {
    'en': 'English',
    'hi': 'Hindi',
    'pa': 'Punjabi',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'ar': 'Arabic',
    'zh': 'Chinese',
  };

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_queryController.text.trim().isEmpty) return;
    final notifier = ref.read(recipeGenerationProvider.notifier);
    await notifier.generateRecipe(
      _queryController.text.trim(),
      language: _selectedLanguage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(recipeGenerationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'AI Recipe Generator',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ask AI to create any recipe in any language',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _queryController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'What recipe do you want?',
              hintText:
                  'Example: Spicy Thai basil chicken, Homemade pasta carbonara...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.auto_awesome),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Output Language',
              prefixIcon: Icon(Icons.language),
            ),
            items: _languages.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedLanguage = v ?? 'en'),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: generationState.isLoading ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Recipe'),
          ),
          const SizedBox(height: 24),
          generationState.when(
            data: (recipe) {
              if (recipe == null) return const SizedBox.shrink();
              return Column(
                children: [
                  RecipeCard(
                    recipe: recipe,
                    onTap: () =>
                        context.go('/recipe/${recipe.recipeId}'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(recipeGenerationProvider.notifier).reset();
                      _queryController.clear();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Generate Another'),
                  ),
                ],
              );
            },
            loading: () => const LoadingWidget(
              message: 'AI is generating your recipe...',
            ),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 8),
                  Text(
                    'Could not generate recipe. All AI providers are currently unavailable.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
