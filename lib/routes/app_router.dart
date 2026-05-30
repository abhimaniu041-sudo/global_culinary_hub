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
import '../screens/cuisine/cuisine_dishes_screen.dart';
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
            builder: (context, state) => CuisineDishesScreen(
              cuisineName: state.pathParameters['name'] ?? '',
            ),
          ),
        ],
      ),
    ],
  );
});
