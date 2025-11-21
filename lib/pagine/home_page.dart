import 'package:flutter/material.dart';

import '../theme_modifier.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = AppTheme.themeMode.value;
    final isDark = themeMode == ThemeMode.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 👈 niente freccia indietro
        title: const Text('Home'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              AppTheme.toggleTheme();
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Benvenuto nella Home di Grouply - Team Manager',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: colors.onSurface,
          ),
        ),
      ),
    );
  }
}
