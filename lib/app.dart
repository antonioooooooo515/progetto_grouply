import 'package:flutter/material.dart';

import 'theme_modifier.dart';
import 'pagine/login_page.dart';
import 'pagine/register_page.dart';
import 'pagine/home_page.dart';
import 'pagine/settings_page.dart';
import 'pagine/profile_settings_page.dart'; // 👈 IMPORT AGGIUNTO

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Grouply - Team Manager',
          themeMode: themeMode,

          // 🌞 LIGHT THEME
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE91E63),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F5F5),
              elevation: 0,
            ),
          ),

          // 🌙 DARK THEME
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE91E63),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF242424),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF242424),
              elevation: 0,
            ),
          ),

          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/home': (context) => const HomePage(),
            '/settings': (context) => const SettingsPage(),
            '/profile-settings': (context) => const ProfileSettingsPage(), // 👈 QUI
          },
        );
      },
    );
  }
}
