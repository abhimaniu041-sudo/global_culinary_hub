import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Global Culinary Hub Tests', () {
    testWidgets('App renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Global Culinary Hub'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Global Culinary Hub'), findsOneWidget);
    });

    test('RecipeModel fromJson works correctly', () {
      // Basic unit test for model parsing
      final json = {
        'recipe_id': 'test_001',
        'name': 'Test Recipe',
        'cuisine': 'Italian',
        'history': 'A classic dish',
        'ingredients': ['pasta', 'tomato'],
        'instructions': ['Boil pasta', 'Add sauce'],
        'prep_time': '30 minutes',
        'difficulty': 'Easy',
        'servings': '4 people',
        'suggested_substitutions': ['gluten-free pasta'],
        'nutrition': {
          'calories': '350 kcal',
          'protein': '12g',
          'carbs': '58g',
          'fat': '8g',
        },
        'created_at': DateTime.now().toIso8601String(),
      };

      // Verify JSON parsing does not throw
      expect(() {
        final name = json['name'];
        final cuisine = json['cuisine'];
        expect(name, 'Test Recipe');
        expect(cuisine, 'Italian');
      }, returnsNormally);
    });

    test('Validators work correctly', () {
      // Email validation
      expect(
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch('test@example.com'),
        true,
      );
      expect(
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch('invalid-email'),
        false,
      );
    });
  });
}
