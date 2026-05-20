import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Tasks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}

class AppTheme {
  static const Color cream = Color(0xFFF5F0E8);
  static const Color ink = Color(0xFF1A1A2E);
  static const Color inkLight = Color(0xFF2D2D44);
  static const Color accent = Color(0xFFE84855);
  static const Color accentSoft = Color(0xFFFDE8EA);
  static const Color muted = Color(0xFF8A8A9A);
  static const Color divider = Color(0xFFE0D9CF);
  static const Color checkGreen = Color(0xFF4CAF7D);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: const ColorScheme.light(
        primary: ink,
        secondary: accent,
        surface: cream,
        onPrimary: cream,
        onSecondary: Colors.white,
        onSurface: ink,
      ),
      fontFamily: 'serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: ink),
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: ink, fontWeight: FontWeight.w700, letterSpacing: -1),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: ink, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.4),
        labelSmall: TextStyle(color: muted, fontSize: 11, letterSpacing: 1.5),
      ),
    );
  }
}
