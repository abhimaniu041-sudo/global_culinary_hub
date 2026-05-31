import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ai/ai_orchestrator.dart';
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
      _results = [];
    });
    try {
      final orchestrator = ref.read(aiOrchestratorProvider);
      final prompt =
          'List 8 dishes matching "$query". Respond ONLY with valid JSON array: [{"recipe_id":"id1","name":"Name","cuisine":"Type","history":"history","ingredients":["i1"],"instructions":["Step 1"],"prep_time":"30 min","difficulty":"Easy","servings":"4","suggested_substitutions":["s1"],"nutrition":{"calories":"300 kcal","protein":"20g","carbs":"30g","fat":"10g"}}]';
      final response = await orchestrator.generateText(prompt);
      final start = response.indexOf('[');
      final end = response.lastIndexOf(']');
      if (start >= 0 && end > start) {
        final jsonStr = response.substring(start, end + 1);
        final list = jsonDecode(jsonStr) as List;
        setState(() {
          _results = list
              .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const LoadingWidget(message: 'AI is searching recipes...');
    }
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
            const Text('No results found'),
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
          onTap: () => context.go(
              '/dish?name=${Uri.encodeComponent(recipe.name)}&img='),
        );
      },
    );
  }
}
