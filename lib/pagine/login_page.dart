import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

import '../theme_modifier.dart';
import '../localization/app_localizations.dart';
import '../widgets/welcome_header.dart';
import '../widgets/soft_card.dart';
import '../widgets/soft_input.dart';
import '../widgets/big_button.dart';
import '../widgets/tiny_text_button.dart';

// ✅ IMPORT DEL SERVICE NOTIFICHE
import '../services/push_notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscured = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ✅ Dopo login OK: inizializza FCM + naviga
  /// (mostra anche l'errore reale se fallisce, non solo "push_init_failed")
  Future<void> _afterAuthSuccess() async {
    final loc = AppLocalizations.of(context);

    try {
      // Inizializza push + salva token su Firestore
      await PushNotificationsService.instance.init();
    } catch (e) {
      // Non blocchiamo l'accesso se le notifiche falliscono
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${loc.t('push_init_failed')}: $e"),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _onLoginPressed() async {
    final loc = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      await _afterAuthSuccess();
    } on FirebaseAuthException catch (e) {
      String message = loc.t('error_login');

      if (e.code == 'user-not-found') {
        message = loc.t('error_user_not_found');
      } else if (e.code == 'wrong-password') {
        message = loc.t('error_wrong_password');
      } else if (e.code == 'invalid-email') {
        message = loc.t('error_invalid_email');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('error_unexpected_login'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final loc = AppLocalizations.of(context);

    if (_isGoogleLoading || _isLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }

      if (!mounted) return;
      await _afterAuthSuccess();
    } on FirebaseAuthException catch (e) {
      String msg = loc.t('error_google_login');

      if (e.code == 'account-exists-with-different-credential') {
        msg = loc.t('error_account_exists_different_credential');
      } else if (e.code == 'invalid-credential') {
        msg = loc.t('error_invalid_google_credential');
      } else if (e.code == 'user-disabled') {
        msg = loc.t('error_user_disabled');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${loc.t('error_google_login_generic')}: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.themeMode.value == ThemeMode.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            Image.asset(
              'lib/assets/logo/logo_nobg.png',
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text(
              "Grouply",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            iconSize: 28,
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              AppTheme.toggleTheme();
              setState(() {});
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WelcomeHeader(
                  title: loc.t('login_title'),
                  subtitle: loc.t('login_subtitle'),
                ),
                const SizedBox(height: 32),
                SoftCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SoftInput(
                              controller: _emailController,
                              label: loc.t('email_label'),
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return loc.t('validation_insert_email');
                                }
                                if (!value.contains('@')) {
                                  return loc.t('validation_email_invalid');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SoftInput(
                              controller: _passwordController,
                              label: loc.t('password_label'),
                              icon: Icons.lock_outline,
                              obscureText: _isObscured,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return loc.t('validation_insert_password');
                                }
                                if (value.length < 6) {
                                  return loc.t('validation_min_6_chars');
                                }
                                return null;
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscured = !_isObscured;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            TinyTextButton(
                              text: loc.t('forgot_password'),
                              alignment: Alignment.centerRight,
                              onPressed: () {
                                // TODO: reset password
                              },
                            ),
                            const SizedBox(height: 10),
                            BigButton(
                              text: loc.t('login_button'),
                              isLoading: _isLoading,
                              onPressed: _onLoginPressed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'oppure',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          icon: _isGoogleLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : Image.asset(
                            'lib/assets/logo/google_logo.png',
                            height: 24,
                          ),
                          label: Text(
                            _isGoogleLoading
                                ? loc.t('login_with_google_loading')
                                : loc.t('login_with_google'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loc.t('no_account')),
                    TinyTextButton(
                      text: loc.t('go_to_register'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
