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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isObscured = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isRegistered = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    final loc = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isRegistered = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('registration_success').split('\n').first),
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 7), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    } on FirebaseAuthException catch (e) {
      String message = loc.t('error_register');
      if (e.code == 'email-already-in-use') {
        message = loc.t('error_email_in_use');
      } else if (e.code == 'weak-password') {
        message = loc.t('error_weak_password');
      } else if (e.code == 'invalid-email') {
        message = loc.t('error_invalid_email');
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('error_unexpected_register'))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    final loc = AppLocalizations.of(context);

    if (_isGoogleLoading || _isLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      UserCredential credential;

      if (kIsWeb) {
        credential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        credential = await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }

      if (!mounted) return;

      setState(() {
        _isRegistered = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('registration_success').split('\n').first),
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 7), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    } on FirebaseAuthException catch (e) {
      String msg = 'Errore durante la registrazione con Google';
      if (e.code == 'account-exists-with-different-credential') {
        msg = 'Esiste già un account con un altro metodo di accesso.';
      } else if (e.code == 'invalid-credential') {
        msg = 'Credenziale Google non valida.';
      } else if (e.code == 'user-disabled') {
        msg = 'Questo account è stato disabilitato.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore Google registrazione: $e')),
      );
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
              'lib/assets/logo/logo_nobg.png', // Logo
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
            iconSize: 32,
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
                  title: loc.t('register_title'),
                  subtitle: loc.t('register_subtitle'),
                ),
                const SizedBox(height: 32),
                SoftCard(
                  child: _isRegistered
                      ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        loc.t('registration_success'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 24),
                      BigButton(
                        text: loc.t('go_to_login_button'),
                        isLoading: false,
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                      ),
                    ],
                  )
                      : Column(
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
                                  return loc.t('validation_insert_password_register');
                                }
                                if (value.length < 6) {
                                  return loc.t('validation_min_6_chars');
                                }
                                return null;
                              },
                              suffixIcon: IconButton(
                                icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _isObscured = !_isObscured;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            SoftInput(
                              controller: _confirmController,
                              label: loc.t('confirm_password_label'),
                              icon: Icons.lock_outline,
                              obscureText: _isObscured,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return loc.t('validation_confirm_password');
                                }
                                if (value != _passwordController.text) {
                                  return loc.t('validation_passwords_not_match');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            BigButton(
                              text: loc.t('register_button'),
                              isLoading: _isLoading,
                              onPressed: _onRegisterPressed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade400, thickness: 0.8)),
                          const SizedBox(width: 8),
                          Text('oppure', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(child: Divider(color: Colors.grey.shade400, thickness: 0.8)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // PULSANTE GOOGLE CON LOGO REALE
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isGoogleLoading ? null : _signUpWithGoogle,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          icon: _isGoogleLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Image.asset(
                            'lib/assets/logo/google_logo.png', // 👈 LOGO REALE
                            height: 24,
                          ),
                          label: Text(
                            _isGoogleLoading ? 'Registrazione con Google...' : loc.t('register_with_google'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
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
                    Text(loc.t('have_account')),
                    TinyTextButton(
                      text: loc.t('login_button'),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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