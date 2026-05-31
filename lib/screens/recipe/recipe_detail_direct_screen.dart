import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai/ai_orchestrator.dart';
import '../../models/recipe_model.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/loading_widget.dart';

final _directRecipeProvider =
    FutureProvider.family<RecipeModel?, String>((ref, query) async {
  final orchestrator = ref.read(aiOrchestratorProvider);
  return orchestrator.generateRecipe(query);
});

class RecipeDetailDirectScreen extends ConsumerWidget {
  final String dishName;
  final String? imageUrl;
  const RecipeDetailDirectScreen({
    super.key,
    required this.dishName,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(_directRecipeProvider(dishName));
    final colorScheme = Theme.of(context).colorScheme;

    return recipeAsync.when(
      data: (recipe) {
        if (recipe == null) {
          return Scaffold(
            appBar: AppBar(title: Text(dishName)),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Could not load recipe'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(_directRecipeProvider(dishName)),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }
        return _RecipeContent(recipe: recipe, imageUrl: imageUrl);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(dishName)),
        body: LoadingWidget(message: 'AI is preparing $dishName recipe...'),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(dishName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              const Text('Failed to generate recipe'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(_directRecipeProvider(dishName)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeContent extends ConsumerWidget {
  final RecipeModel recipe;
  final String? imageUrl;
  const _RecipeContent({required this.recipe, this.imageUrl});

  void _shareRecipe(BuildContext context) {
    final text = '''
${recipe.name} Recipe

Cuisine: ${recipe.cuisine}
Prep Time: ${recipe.prepTime}
Difficulty: ${recipe.difficulty}
Servings: ${recipe.servings}

INGREDIENTS:
${recipe.ingredients.map((i) => '• $i').join('\n')}

INSTRUCTIONS:
${recipe.instructions.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

NUTRITION:
Calories: ${recipe.nutrition.calories}
Protein: ${recipe.nutrition.protein}
Carbs: ${recipe.nutrition.carbs}
Fat: ${recipe.nutrition.fat}

Shared from Global Culinary Hub
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFav = ref.watch(favoritesProvider.notifier).isFavorite(recipe.recipeId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.white,
                ),
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggleFavorite(recipe),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareRecipe(context),
                tooltip: 'Copy recipe',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
              background: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        color: colorScheme.primaryContainer,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (ctx, url, err) => Container(
                        color: colorScheme.primaryContainer,
                        child: Icon(Icons.restaurant,
                            size: 80, color: colorScheme.primary),
                      ),
                    )
                  : Container(
                      color: colorScheme.primaryContainer,
                      child: Icon(Icons.restaurant,
                          size: 80, color: colorScheme.primary),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(recipe.cuisine, Icons.public),
                      _InfoChip(recipe.difficulty, Icons.bar_chart),
                      _InfoChip(recipe.prepTime, Icons.timer),
                      _InfoChip('Serves ${recipe.servings}', Icons.people),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader('Nutrition'),
                  _NutritionChart(nutrition: recipe.nutrition),
                  const SizedBox(height: 20),
                  if (recipe.history.isNotEmpty) ...[
                    _SectionHeader('History & Culture'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(recipe.history),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _SectionHeader('Ingredients'),
                  ...recipe.ingredients.map(
                    (ing) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(ing)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader('Instructions'),
                  ...recipe.instructions.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(entry.value)),
                        ],
                      ),
                    ),
                  ),
                  if (recipe.suggestedSubstitutions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SectionHeader('Substitutions'),
                    ...recipe.suggestedSubstitutions.map(
                      (sub) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(sub)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareRecipe(context),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Recipe to Share'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionChart extends StatelessWidget {
  final NutritionModel nutrition;
  const _NutritionChart({required this.nutrition});

  double _parseValue(String val) {
    final num = RegExp(r'[\d.]+').firstMatch(val)?.group(0);
    return double.tryParse(num ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final protein = _parseValue(nutrition.protein);
    final carbs = _parseValue(nutrition.carbs);
    final fat = _parseValue(nutrition.fat);
    final total = protein + carbs + fat;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NutCard('Calories', nutrition.calories, Colors.orange),
            ),
            const SizedBox(width: 8),
            Expanded(child: _NutCard('Protein', nutrition.protein, Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _NutCard('Carbs', nutrition.carbs, Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _NutCard('Fat', nutrition.fat, Colors.red)),
          ],
        ),
        const SizedBox(height: 12),
        if (total > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  if (protein > 0)
                    Flexible(
                      flex: protein.round(),
                      child: Container(color: Colors.blue),
                    ),
                  if (carbs > 0)
                    Flexible(
                      flex: carbs.round(),
                      child: Container(color: Colors.green),
                    ),
                  if (fat > 0)
                    Flexible(
                      flex: fat.round(),
                      child: Container(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(Colors.blue, 'Protein'),
              const SizedBox(width: 12),
              _LegendDot(Colors.green, 'Carbs'),
              const SizedBox(width: 12),
              _LegendDot(Colors.red, 'Fat'),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _NutCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NutCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 12)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
