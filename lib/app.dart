import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme_modifier.dart';
import 'localization/app_localizations.dart';

import 'pagine/login_page.dart';
import 'pagine/register_page.dart';
import 'pagine/home_page.dart';
import 'pagine/settings_page.dart';
import 'pagine/profile_settings_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.locale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeMode,
          builder: (context, themeMode, _) {

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Grouply - Team Manager',

              // --- GESTIONE LINGUA ---
              locale: locale,
              supportedLocales: const [
                Locale('it'), // Italiano
                Locale('en'), // Inglese
                Locale('es'), // Spagnolo
                Locale('fr'), // Francese (NUOVO)
                Locale('de'), // Tedesco (NUOVO)
                Locale('pt'), // Portoghese (NUOVO)
              ],
              localizationsDelegates: const [
                AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // --- GESTIONE TEMA ---
              themeMode: themeMode,

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
                  iconTheme: IconThemeData(color: Colors.black),
                ),
              ),

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
                  iconTheme: IconThemeData(color: Colors.white),
                ),
              ),

              // --- ROUTES ---
              initialRoute: '/login',
              routes: {
                '/login': (context) => const LoginPage(),
                '/register': (context) => const RegisterPage(),
                '/home': (context) => const HomePage(),
                '/settings': (context) => const SettingsPage(),
                '/profile-settings': (context) => const ProfileSettingsPage(),
              },
            );
          },
        );
      },
    );
  }
}