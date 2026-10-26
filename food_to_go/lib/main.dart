import 'package:flutter/material.dart';
import 'package:food_to_go/auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://csofjnidriuxxhrwzszn.supabase.co',
  );
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_mgKw3tvEdOds8sLxxFat5Q_n8qIXvbD',
  );
  final supabaseConfigured =
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  if (supabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  runApp(FoodToGoApp(supabaseConfigured: supabaseConfigured));
}

class FoodToGoApp extends StatelessWidget {
  const FoodToGoApp({super.key, required this.supabaseConfigured});

  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) {
    const sage = Color(0xFF929F78);
    const cream = Color(0xFFF7F3ED);
    const warmWhite = Color(0xFFFFFCF7);
    const ink = Color(0xFF302F27);
    final colorScheme = ColorScheme.fromSeed(seedColor: sage, surface: cream)
        .copyWith(
          primary: sage,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFE3E8D9),
          onPrimaryContainer: const Color(0xFF303927),
          secondary: const Color(0xFFE8DFD3),
          onSecondary: ink,
          surface: cream,
          onSurface: ink,
          outline: const Color(0xFF888477),
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food to Go',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: warmWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD8D0C4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD8D0C4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: sage, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: sage,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: AuthScreen(supabaseConfigured: supabaseConfigured),
    );
  }
}
