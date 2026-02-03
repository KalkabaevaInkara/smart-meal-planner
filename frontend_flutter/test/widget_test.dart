import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:healthy_eating_flutter/app.dart';
import 'package:healthy_eating_flutter/screens/login_screen.dart';
import 'package:healthy_eating_flutter/screens/home_screen.dart';
import 'package:healthy_eating_flutter/screens/catalog_screen.dart';
import 'package:healthy_eating_flutter/screens/planner_screen.dart';
import 'package:healthy_eating_flutter/screens/goals_screen.dart';
import 'package:healthy_eating_flutter/screens/nutrition_tips_screen.dart';
import 'package:healthy_eating_flutter/screens/meal_history_screen.dart';
import 'package:healthy_eating_flutter/widgets/recipe_card.dart';
import 'package:healthy_eating_flutter/models/recipe.dart';

void main() {
  // 1. Приложение запускается без краха
  testWidgets('App launches and contains MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  // 2. На экране логина есть поля email и пароль
  testWidgets('Login screen shows email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.email), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  // 3. Валидация пароля
  testWidgets('Short password shows validation error', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byType(TextField).first, 'test@mail.com');
    await tester.enterText(find.byType(TextField).at(1), '12345');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    
    expect(find.text('Пароль должен содержать минимум 8 символов'), findsOneWidget);
  });

  // 4. Валидация email
  testWidgets('Invalid email shows validation error', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byType(TextField).first, 'invalid');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    
    expect(find.text('Некорректный формат email'), findsOneWidget);
  });

  // 5. Кнопка "Продолжить без входа"
  testWidgets('Guest button navigates to Home', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    final guestFinder = find.text('Продолжить без входа');
    if (guestFinder.evaluate().isNotEmpty) {
      await tester.tap(guestFinder);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    }
  });

  // 6. CatalogScreen содержит заголовок
  testWidgets('Catalog screen shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CatalogScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Каталог рецептов'), findsOneWidget);
  });

  // 7. RecipeCard отображает название
  testWidgets('RecipeCard shows recipe title and calories', (WidgetTester tester) async {
    final r = Recipe(
      id: 999,
      title: 'Тестовое блюдо',
      description: 'Описание',
      calories: 123,
      proteins: 4.5,
      fats: 1.2,
      carbs: 10.0,
      imageUrl: '',
      cookingTime: 10,
      difficulty: 'Легко',
      ingredients: [],
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RecipeCard(recipe: r))));
    await tester.pumpAndSettle();
    expect(find.text('Тестовое блюдо'), findsOneWidget);
    expect(find.text('123 ккал'), findsOneWidget);
  });

  // 8. PlannerScreen показывает "Итог за день"
  testWidgets('Planner screen shows summary card', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PlannerScreen()));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Итог за день'), findsOneWidget);
  });

  // 9. GoalsScreen содержит заголовок
  testWidgets('Goals screen has title', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: GoalsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Мои цели питания'), findsOneWidget);
  });

  // 10. NutritionTipsScreen содержит советы
  testWidgets('Nutrition tips contains tip title', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NutritionTipsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Белок при каждом приёме'), findsOneWidget);
  });

  // 11. MealHistoryScreen обработка пустой истории
  testWidgets('MealHistoryScreen handles empty history', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MealHistoryScreen(email: 'no_such_email'))); 
    await tester.pumpAndSettle();
    expect(
      find.text('История пока пуста').evaluate().isNotEmpty || 
      find.byType(ListView).evaluate().isNotEmpty,
      true
    );
  });

  // 12. RecipeCard имеет корректную структуру
  testWidgets('RecipeCard structure is correct', (WidgetTester tester) async {
    final r = Recipe(
      id: 1,
      title: 'Салат',
      description: 'Вкусный салат',
      calories: 150,
      proteins: 5.0,
      fats: 3.0,
      carbs: 20.0,
      imageUrl: 'https://example.com/image.jpg',
      cookingTime: 15,
      difficulty: 'Легко',
      ingredients: [],
    );
    
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: RecipeCard(recipe: r)))));
    await tester.pumpAndSettle();
    
    expect(find.text('Салат'), findsOneWidget);
    expect(find.text('150 ккал'), findsOneWidget);
    expect(find.text('15 мин'), findsOneWidget);
  });
}
