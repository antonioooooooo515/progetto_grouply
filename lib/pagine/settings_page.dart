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
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      case 'pt': return 'Português';
      case 'it':
      default:   return 'Italiano';
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
          child: SingleChildScrollView(
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
                  leading: const Text("🇮🇹", style: TextStyle(fontSize: 24)),
                  title: Text(loc.t('language_italian')),
                  onTap: () => Navigator.pop(context, 'it'),
                ),
                ListTile(
                  leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
                  title: Text(loc.t('language_english')),
                  onTap: () => Navigator.pop(context, 'en'),
                ),
                ListTile(
                  leading: const Text("🇪🇸", style: TextStyle(fontSize: 24)),
                  title: Text(loc.t('language_spanish')),
                  onTap: () => Navigator.pop(context, 'es'),
                ),
                ListTile(
                  leading: const Text("🇫🇷", style: TextStyle(fontSize: 24)),
                  title: Text(loc.t('language_french')),
                  onTap: () => Navigator.pop(context, 'fr'),
                ),
                ListTile(
                  leading: const Text("🇩🇪", style: TextStyle(fontSize: 24)),
                  title: Text(loc.t('language_german')),
                  onTap: () => Navigator.pop(context, 'de'),
                ),
                ListTile(
                  leading: const Text("🇧🇷", style: TextStyle(fontSize: 24)),
                  title: Text(loc.t('language_portuguese')),
                  onTap: () => Navigator.pop(context, 'pt'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && mounted) {
      Locale newLocale = Locale(result);
      _selectedLanguage = _labelForCode(result);

      AppLanguage.setLocale(newLocale);
      setState(() {});

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  loc.t('language_changed_snackbar', params: {'language': _selectedLanguage}),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),

          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black.withOpacity(0.9),
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          shape: const StadiumBorder(),
          duration: const Duration(milliseconds: 2000),
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
        // 🔥 PULSANTE INDIETRO INTELLIGENTE
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Se c'è una pagina precedente, torna indietro
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Se non c'è (es. dopo Hot Restart), vai forzatamente alla Home
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // TEMA
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

                  // ACCOUNT
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
                      subtitle: Text(loc.t('settings_account_email_subtitle')),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PROFILO
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
                      subtitle: Text(loc.t('settings_profile_manage_subtitle')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(context, '/profile-settings');
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // LINGUA
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

            // LOGOUT
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