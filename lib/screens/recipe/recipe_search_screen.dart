import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/recipe_provider.dart';
import '../../services/recipe_service.dart';
import '../../models/recipe_model.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/loading_widget.dart';

class RecipeSearchScreen extends ConsumerStatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  ConsumerState<RecipeSearchScreen> createState() =>
      _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends ConsumerState<RecipeSearchScreen> {
  final _searchController = TextEditingController();
  List<RecipeModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final recipeService = ref.read(recipeServiceProvider);
      final results = await recipeService.searchRecipes(query);
      setState(() => _results = results);
    } catch (e) {
      setState(() => _results = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SearchBar(
            controller: _searchController,
            hintText: 'Search recipes, cuisines, ingredients...',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _results = [];
                      _hasSearched = false;
                    });
                  },
                ),
            ],
            onSubmitted: _search,
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                context.go(
                    '/generate?q=${Uri.encodeComponent(_searchController.text.trim())}');
              }
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Generate with AI'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) return const LoadingWidget();

    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Search for any recipe or cuisine',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_meals, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No recipes found'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => context.go(
                  '/generate?q=${Uri.encodeComponent(_searchController.text.trim())}'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate with AI'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final recipe = _results[index];
        return RecipeCard(
          recipe: recipe,
          onTap: () => context.go('/recipe/${recipe.recipeId}'),
        );
      },
    );
  }
}
