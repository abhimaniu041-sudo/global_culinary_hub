import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/recipe_model.dart';
import '../../providers/recipe_provider.dart';
import '../../services/recipe_service.dart';
import '../../widgets/loading_widget.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(_recipeDetailProvider(recipeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        actions: [
          recipeAsync.maybeWhen(
            data: (recipe) {
              if (recipe == null) return const SizedBox.shrink();
              final isFav = ref
                  .watch(favoritesProvider.notifier)
                  .isFavorite(recipe.recipeId);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                onPressed: () => ref
                    .read(favoritesProvider.notifier)
                    .toggleFavorite(recipe),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: recipeAsync.when(
        data: (recipe) {
          if (recipe == null) {
            return const Center(child: Text('Recipe not found'));
          }
          return _RecipeDetailContent(recipe: recipe);
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

final _recipeDetailProvider =
    FutureProvider.family<RecipeModel?, String>((ref, id) async {
  final service = ref.read(recipeServiceProvider);
  return service.getRecipeById(id);
});

class _RecipeDetailContent extends StatelessWidget {
  final RecipeModel recipe;
  const _RecipeDetailContent({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipe.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(
                  label: recipe.cuisine, icon: Icons.public),
              const SizedBox(width: 8),
              _InfoChip(
                  label: recipe.difficulty, icon: Icons.bar_chart),
              const SizedBox(width: 8),
              _InfoChip(
                  label: recipe.prepTime, icon: Icons.timer_outlined),
            ],
          ),
          const SizedBox(height: 16),
          if (recipe.history.isNotEmpty) ...[
            _SectionTitle('History'),
            Text(recipe.history,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
          ],
          _SectionTitle('Nutrition (per serving)'),
          Row(
            children: [
              _NutritionCard(
                  label: 'Calories',
                  value: recipe.nutrition.calories,
                  color: Colors.orange),
              const SizedBox(width: 8),
              _NutritionCard(
                  label: 'Protein',
                  value: recipe.nutrition.protein,
                  color: Colors.blue),
              const SizedBox(width: 8),
              _NutritionCard(
                  label: 'Carbs',
                  value: recipe.nutrition.carbs,
                  color: Colors.green),
              const SizedBox(width: 8),
              _NutritionCard(
                  label: 'Fat',
                  value: recipe.nutrition.fat,
                  color: Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle('Ingredients'),
          ...recipe.ingredients.map((ingredient) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle,
                        size: 8, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ingredient)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          _SectionTitle('Instructions'),
          ...recipe.instructions.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
            const SizedBox(height: 16),
            _SectionTitle('Suggested Substitutions'),
            ...recipe.suggestedSubstitutions.map((sub) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(sub)),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

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
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NutritionCard(
      {required this.label, required this.value, required this.color});

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
                    fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
