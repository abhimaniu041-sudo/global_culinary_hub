import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/recipe/recipe_search_screen.dart';
import '../screens/recipe/recipe_detail_screen.dart';
import '../screens/recipe/recipe_generate_screen.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/chat/ai_chat_screen.dart';
import '../screens/dashboard/monitoring_dashboard.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && state.matchedLocation == '/login') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeContent(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const RecipeSearchScreen(),
          ),
          GoRoute(
            path: '/recipe/:id',
            builder: (context, state) => RecipeDetailScreen(
              recipeId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: '/generate',
            builder: (context, state) => const RecipeGenerateScreen(),
          ),
          GoRoute(
            path: '/camera',
            builder: (context, state) => const CameraScreen(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const AiChatScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const MonitoringDashboard(),
          ),
          GoRoute(
            path: '/cuisine/:name',
            builder: (context, state) {
              final name = state.pathParameters['name'] ?? '';
              return _CuisineSearchScreen(cuisineName: name);
            },
          ),
        ],
      ),
    ],
  );
});

class _CuisineSearchScreen extends ConsumerWidget {
  final String cuisineName;
  const _CuisineSearchScreen({required this.cuisineName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('$cuisineName Cuisine')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Popular $cuisineName Dishes',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap any dish to generate its complete recipe with AI',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _CuisineDishList(cuisineName: cuisineName),
            ),
          ],
        ),
      ),
    );
  }
}

final _dishListProvider =
    FutureProvider.family<List<String>, String>((ref, cuisine) async {
  final orchestrator = ref.read(
      Provider((r) => r.read(
          Provider((r2) => null))));
  return _getDefaultDishes(cuisine);
});

List<String> _getDefaultDishes(String cuisine) {
  final dishes = {
    'Italian': ['Pizza Margherita', 'Pasta Carbonara', 'Lasagna', 'Risotto', 'Tiramisu', 'Osso Buco', 'Bruschetta', 'Minestrone', 'Gnocchi', 'Panna Cotta', 'Arancini', 'Cannoli'],
    'Indian': ['Butter Chicken', 'Biryani', 'Dal Makhani', 'Palak Paneer', 'Chole Bhature', 'Samosa', 'Naan', 'Tandoori Chicken', 'Gulab Jamun', 'Dosa', 'Pav Bhaji', 'Rogan Josh'],
    'Mexican': ['Tacos', 'Enchiladas', 'Guacamole', 'Tamales', 'Chiles Rellenos', 'Pozole', 'Mole Poblano', 'Quesadilla', 'Burrito', 'Churros', 'Elote', 'Horchata'],
    'Japanese': ['Sushi', 'Ramen', 'Tempura', 'Tonkatsu', 'Miso Soup', 'Yakitori', 'Gyoza', 'Udon', 'Takoyaki', 'Matcha Ice Cream', 'Onigiri', 'Teriyaki'],
    'Chinese': ['Kung Pao Chicken', 'Dim Sum', 'Peking Duck', 'Fried Rice', 'Hot Pot', 'Mapo Tofu', 'Spring Rolls', 'Wonton Soup', 'Char Siu', 'Xiaolongbao', 'Congee', 'Chow Mein'],
    'French': ['Croissant', 'Coq au Vin', 'Ratatouille', 'Bouillabaisse', 'Crème Brûlée', 'Quiche Lorraine', 'Escargot', 'Soufflé', 'Beef Bourguignon', 'Crepes', 'French Onion Soup', 'Macarons'],
    'Thai': ['Pad Thai', 'Tom Yum', 'Green Curry', 'Som Tum', 'Massaman Curry', 'Khao Pad', 'Mango Sticky Rice', 'Tom Kha Gai', 'Larb', 'Pad See Ew', 'Thai Spring Rolls', 'Satay'],
    'American': ['Burger', 'BBQ Ribs', 'Mac and Cheese', 'Clam Chowder', 'Buffalo Wings', 'Apple Pie', 'Pancakes', 'Lobster Roll', 'Cheesesteak', 'Gumbo', 'Cornbread', 'Key Lime Pie'],
  };
  return dishes[cuisine] ?? List.generate(12, (i) => '$cuisine Dish ${i + 1}');
}

class _CuisineDishList extends ConsumerWidget {
  final String cuisineName;
  const _CuisineDishList({required this.cuisineName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dishes = _getDefaultDishes(cuisineName);
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      itemCount: dishes.length,
      itemBuilder: (context, index) {
        final dish = dishes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
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
            title: Text(
              dish,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '$cuisineName cuisine',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => context.go(
                  '/generate?q=${Uri.encodeComponent(dish)}'),
              icon: const Icon(Icons.auto_awesome, size: 14),
              label: const Text('Recipe', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
              ),
            ),
            onTap: () => context.go(
                '/generate?q=${Uri.encodeComponent(dish)}'),
          ),
        );
      },
    );
  }
}
