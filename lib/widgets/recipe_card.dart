import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
  });

  Color get _difficultyColor {
    switch (recipe.difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onFavoriteToggle != null)
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : null,
                      ),
                      onPressed: onFavoriteToggle,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Tag(recipe.cuisine, colorScheme.primaryContainer),
                  const SizedBox(width: 8),
                  _Tag(
                      recipe.difficulty,
                      _difficultyColor.withOpacity(0.2),
                      textColor: _difficultyColor),
                  const SizedBox(width: 8),
                  Icon(Icons.timer_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    recipe.prepTime,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_fire_department_outlined,
                      size: 14,
                      color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    recipe.nutrition.calories,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    recipe.servings,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color? textColor;

  const _Tag(this.label, this.backgroundColor, {this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
