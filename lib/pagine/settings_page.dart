import 'package:flutter/material.dart';
import '../theme_modifier.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.themeMode.value == ThemeMode.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Sezione PREFERENZE
          Text(
            'Preferenze',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Tema scuro'),
            value: isDark,
            onChanged: (_) {
              AppTheme.toggleTheme();
            },
          ),

          const Divider(height: 32),

          // 🔹 Gestione profilo → ora apre una pagina dedicata
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Gestione profilo'),
            subtitle: const Text('Modifica i dati del tuo account'),
            onTap: () {
              Navigator.pushNamed(context, '/profile-settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifiche'),
            subtitle: const Text('Preferenze di notifica'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text('Impostazioni sulla privacy'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
