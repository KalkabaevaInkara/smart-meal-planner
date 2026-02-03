import 'package:flutter/material.dart';
// import 'package:device_preview/device_preview.dart'; // removed
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'models/recipe.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthy Eating',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF43A047)),
        useMaterial3: false,
      ),
      // useInheritedMediaQuery: true,
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/recipe': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final recipe = args is Recipe ? args : throw Exception('Recipe expected in arguments');
          return RecipeDetailScreen(recipe: recipe);
        },
      },
    );
  }
}
