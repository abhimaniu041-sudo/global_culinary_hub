import 'package:flutter/material.dart';
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

    return Scaffold(
      body: recipeAsync.when(
        data: (recipe) {
          if (recipe == null) {
            return Scaffold(
              appBar: AppBar(title: Text(dishName)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Could not load recipe'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(_directRecipeProvider(dishName)),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _RecipeContent(
              recipe: recipe, imageUrl: imageUrl);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: Text(dishName)),
          body: LoadingWidget(
            message: 'AI is preparing $dishName recipe...',
          ),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: Text(dishName)),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                const Text('Failed to generate recipe'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(_directRecipeProvider(dishName)),
                  child: const Text('Retry'),
                ),
              ],
            ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFav = ref
        .watch(favoritesProvider.notifier)
        .isFavorite(recipe.recipeId);

    return CustomScrollView(
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
              onPressed: () => ref
                  .read(favoritesProvider.notifier)
                  .toggleFavorite(recipe),
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
            background: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      color: colorScheme.primaryContainer,
                      child: const Center(
                          child: CircularProgressIndicator()),
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
                  children: [
                    _Chip(recipe.cuisine, Icons.public),
                    _Chip(recipe.difficulty, Icons.bar_chart),
                    _Chip(recipe.prepTime, Icons.timer),
                    _Chip('Serves ${recipe.servings}', Icons.people),
                  ],
                ),
                const SizedBox(height: 16),
                _NutritionRow(nutrition: recipe.nutrition),
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
                                fontSize: 12,
                              ),
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
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
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(bottom: 6),
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

class _NutritionRow extends StatelessWidget {
  final NutritionModel nutrition;
  const _NutritionRow({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NutCard('Calories', nutrition.calories, Colors.orange),
        const SizedBox(width: 8),
        _NutCard('Protein', nutrition.protein, Colors.blue),
        const SizedBox(width: 8),
        _NutCard('Carbs', nutrition.carbs, Colors.green),
        const SizedBox(width: 8),
        _NutCard('Fat', nutrition.fat, Colors.red),
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
    return Expanded(
      child: Container(
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
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 12)),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
