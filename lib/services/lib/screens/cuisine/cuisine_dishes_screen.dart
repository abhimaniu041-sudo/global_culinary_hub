import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/cuisine_service.dart';
import '../../widgets/loading_widget.dart';

final _cuisineDishesProvider =
    FutureProvider.family<List<CuisineDish>, String>((ref, cuisine) async {
  final service = ref.read(cuisineServiceProvider);
  return service.getCuisineDishes(cuisine);
});

class CuisineDishesScreen extends ConsumerWidget {
  final String cuisineName;
  const CuisineDishesScreen({super.key, required this.cuisineName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dishesAsync = ref.watch(_cuisineDishesProvider(cuisineName));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('$cuisineName Cuisine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(_cuisineDishesProvider(cuisineName)),
          ),
        ],
      ),
      body: dishesAsync.when(
        data: (dishes) {
          if (dishes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.no_meals, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Could not load dishes'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(_cuisineDishesProvider(cuisineName)),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              return _DishCard(
                dish: dish,
                cuisineName: cuisineName,
                index: index,
              );
            },
          );
        },
        loading: () => const LoadingWidget(
          message: 'AI is fetching dishes...',
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              const Text('Failed to load dishes'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(_cuisineDishesProvider(cuisineName)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final CuisineDish dish;
  final String cuisineName;
  final int index;

  const _DishCard({
    required this.dish,
    required this.cuisineName,
    required this.index,
  });

  Color get _difficultyColor {
    switch (dish.difficulty.toLowerCase()) {
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
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(
            '/generate?q=${Uri.encodeComponent(dish.name)} ${Uri.encodeComponent(cuisineName)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dish.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (dish.originalName.isNotEmpty &&
                            dish.originalName != dish.name)
                          Text(
                            dish.originalName,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                dish.description,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              if (dish.history.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.history_edu,
                          size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dish.history,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dish.prepTime,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _difficultyColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      dish.difficulty,
                      style: TextStyle(
                        fontSize: 11,
                        color: _difficultyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.go(
                        '/generate?q=${Uri.encodeComponent(dish.name)}'),
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label: const Text('Get Recipe', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
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
