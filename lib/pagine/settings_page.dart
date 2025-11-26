import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme_modifier.dart';
import '../localization/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'Italiano';

  @override
  void initState() {
    super.initState();
    final code = AppLanguage.locale.value.languageCode;
    _selectedLanguage = _labelForCode(code);
  }

  String _labelForCode(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'it':
      default:
        return 'Italiano';
    }
  }

  void _chooseLanguage() async {
    final loc = AppLocalizations.of(context);

    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  loc.t('settings_language_select_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(loc.t('language_italian')),
                onTap: () => Navigator.pop(context, 'it'),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(loc.t('language_english')),
                onTap: () => Navigator.pop(context, 'en'),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(loc.t('language_spanish')),
                onTap: () => Navigator.pop(context, 'es'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      Locale newLocale;

      switch (result) {
        case 'en':
          newLocale = const Locale('en');
          _selectedLanguage = 'English';
          break;
        case 'es':
          newLocale = const Locale('es');
          _selectedLanguage = 'Español';
          break;
        case 'it':
        default:
          newLocale = const Locale('it');
          _selectedLanguage = 'Italiano';
          break;
      }

      AppLanguage.setLocale(newLocale);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.t(
              'language_changed_snackbar',
              params: {'language': _selectedLanguage},
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('settings_title')),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Contenuto scrollabile
            Expanded(
              child: ListView(
                children: [
                  // 1️⃣ SEZIONE TEMA
                  Text(
                    loc.t('settings_section_theme'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ValueListenableBuilder<ThemeMode>(
                      valueListenable: AppTheme.themeMode,
                      builder: (context, themeMode, _) {
                        final isDark = themeMode == ThemeMode.dark;
                        return SwitchListTile(
                          secondary: const Icon(Icons.dark_mode_outlined),
                          title: Text(loc.t('settings_change_theme')),
                          subtitle: Text(
                            isDark
                                ? loc.t('settings_theme_dark_active')
                                : loc.t('settings_theme_light_active'),
                          ),
                          value: isDark,
                          onChanged: (_) {
                            AppTheme.toggleTheme();
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2️⃣ ACCOUNT
                  Text(
                    loc.t('settings_section_account'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(user?.email ?? 'Nessun utente'),
                      subtitle:
                      Text(loc.t('settings_account_email_subtitle')),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3️⃣ PROFILO
                  Text(
                    loc.t('settings_section_profile'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.manage_accounts_outlined),
                      title: Text(loc.t('settings_profile_manage_title')),
                      subtitle:
                      Text(loc.t('settings_profile_manage_subtitle')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(context, '/profile-settings');
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4️⃣ LINGUA
                  Text(
                    loc.t('settings_section_language'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.translate),
                      title: Text(loc.t('settings_language_app')),
                      subtitle: Text(_selectedLanguage),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _chooseLanguage,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔴 Pulsante Esci
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  loc.t('logout_button'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
