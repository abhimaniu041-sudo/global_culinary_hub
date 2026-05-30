import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/recipe/recipe_search_screen.dart';
import '../screens/recipe/recipe_detail_screen.dart';
import '../screens/recipe/recipe_generate_screen.dart';
import '../screens/recipe/recipe_detail_direct_screen.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/chat/ai_chat_screen.dart';
import '../screens/dashboard/monitoring_dashboard.dart';
import '../providers/auth_provider.dart';
import '../services/cuisine_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';
      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && state.matchedLocation == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeContent()),
          GoRoute(path: '/search', builder: (c, s) => const RecipeSearchScreen()),
          GoRoute(
            path: '/recipe/:id',
            builder: (c, s) => RecipeDetailScreen(
              recipeId: s.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(path: '/generate', builder: (c, s) => const RecipeGenerateScreen()),
          GoRoute(path: '/camera', builder: (c, s) => const CameraScreen()),
          GoRoute(path: '/favorites', builder: (c, s) => const FavoritesScreen()),
          GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
          GoRoute(path: '/chat', builder: (c, s) => const AiChatScreen()),
          GoRoute(path: '/dashboard', builder: (c, s) => const MonitoringDashboard()),
          GoRoute(
            path: '/cuisine/:name',
            builder: (c, s) => _CuisineScreen(
              cuisineName: s.pathParameters['name'] ?? '',
            ),
          ),
          GoRoute(
            path: '/dish',
            builder: (c, s) => RecipeDetailDirectScreen(
              dishName: s.uri.queryParameters['name'] ?? '',
              imageUrl: s.uri.queryParameters['img'],
            ),
          ),
        ],
      ),
    ],
  );
});

// ─── Cuisine Screen ────────────────────────────────────────────────────────
final _cuisinePageProvider =
    StateProvider.family<int, String>((ref, cuisine) => 0);

final _cuisineDishesProvider =
    FutureProvider.family<List<CuisineDish>, String>((ref, key) async {
  final parts = key.split('::');
  final cuisine = parts[0];
  final page = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final service = ref.read(cuisineServiceProvider);
  return service.getCuisineDishes(cuisine, page: page);
});

class _CuisineScreen extends ConsumerStatefulWidget {
  final String cuisineName;
  const _CuisineScreen({required this.cuisineName});

  @override
  ConsumerState<_CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends ConsumerState<_CuisineScreen> {
  int _page = 0;
  final List<CuisineDish> _allDishes = [];
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _page++;
    final service = ref.read(cuisineServiceProvider);
    final more =
        await service.getCuisineDishes(widget.cuisineName, page: _page);
    setState(() {
      _allDishes.addAll(more);
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = '${widget.cuisineName}::0';
    final dishesAsync = ref.watch(_cuisineDishesProvider(key));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cuisineName} Cuisine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _allDishes.clear();
              _page = 0;
              ref.invalidate(_cuisineDishesProvider(key));
            },
          ),
        ],
      ),
      body: dishesAsync.when(
        data: (dishes) {
          if (_allDishes.isEmpty) _allDishes.addAll(dishes);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  '${_allDishes.length}+ dishes loaded',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _allDishes.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _allDishes.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _DishTile(
                      dish: _allDishes[index],
                      index: index,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI is loading dishes...'),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(_cuisineDishesProvider(key)),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}

class _DishTile extends StatelessWidget {
  final CuisineDish dish;
  final int index;
  const _DishTile({required this.dish, required this.index});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(
          '/dish?name=${Uri.encodeComponent(dish.name)}&img=${Uri.encodeComponent(dish.imageUrl)}',
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: dish.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(
                  width: 90,
                  height: 90,
                  color: colorScheme.primaryContainer,
                  child: Icon(Icons.restaurant,
                      color: colorScheme.primary),
                ),
                errorWidget: (ctx, url, err) => Container(
                  width: 90,
                  height: 90,
                  color: colorScheme.primaryContainer,
                  child: Icon(Icons.restaurant,
                      color: colorScheme.primary),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (dish.originalName.isNotEmpty &&
                        dish.originalName != dish.name)
                      Text(
                        dish.originalName,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      dish.description,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(dish.prepTime,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dish.difficulty,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_forward_ios, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
