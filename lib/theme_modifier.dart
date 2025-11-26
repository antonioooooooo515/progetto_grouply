import 'package:flutter/material.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeMode =
  ValueNotifier(ThemeMode.light);

  static void toggleTheme() {
    themeMode.value =
    themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

class AppLanguage {
  static final ValueNotifier<Locale> locale =
  ValueNotifier(const Locale('it'));

  static void setLocale(Locale newLocale) {
    locale.value = newLocale;
  }
}
