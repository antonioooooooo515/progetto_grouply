import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme_modifier.dart';
import 'localization/app_localizations.dart';

// Pagine
import 'pagine/splash_page.dart';
import 'pagine/login_page.dart';
import 'pagine/register_page.dart';
import 'pagine/home_page.dart';
import 'pagine/settings_page.dart';
import 'pagine/profile_settings_page.dart';

// 1. Chiave Globale per controllare la navigazione da fuori il contesto
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 2. Trasformato in StatefulWidget per usare WidgetsBindingObserver
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // 3. Iniziamo ad ascoltare lo stato dell'app
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 4. Questa funzione scatta quando l'app viene minimizzata o riaperta
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Se l'app torna in primo piano (Resumed)
    if (state == AppLifecycleState.resumed) {
      // 🔥 FORZA IL RITORNO ALLA SPLASH SCREEN
      // (route) => false rimuove tutte le pagine precedenti dallo stack
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguage.locale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeMode,
          builder: (context, themeMode, _) {

            return MaterialApp(
              // 5. Colleghiamo la chiave globale al navigatore
              navigatorKey: navigatorKey,

              debugShowCheckedModeBanner: false,
              title: 'Grouply - Team Manager',

              // --- GESTIONE LINGUA ---
              locale: locale,
              supportedLocales: const [
                Locale('it'), // Italiano
                Locale('en'), // Inglese
                Locale('es'), // Spagnolo
                Locale('fr'), // Francese
                Locale('de'), // Tedesco
                Locale('pt'), // Portoghese
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
              initialRoute: '/',

              routes: {
                '/': (context) => const SplashPage(),
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