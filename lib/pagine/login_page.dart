import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme_modifier.dart';
import '../widgets/welcome_header.dart';
import '../widgets/soft_card.dart';
import '../widgets/soft_input.dart';
import '../widgets/big_button.dart';
import '../widgets/tiny_text_button.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String message = 'Errore durante il login';

      if (e.code == 'user-not-found') {
        message = 'Utente non trovato';
      } else if (e.code == 'wrong-password') {
        message = 'Password errata';
      } else if (e.code == 'invalid-email') {
        message = 'Email non valida';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore imprevisto durante il login')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.themeMode.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'lib/assets/logo/logo_nobg.png',
              height: 50,
            ),
            const SizedBox(width: 8),
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
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const WelcomeHeader(
                  title: 'Bentornato!',
                  subtitle: 'Accedi per continuare',
                ),
                const SizedBox(height: 32),
                SoftCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SoftInput(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci la tua email';
                            }
                            if (!value.contains('@')) {
                              return 'Email non valida';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SoftInput(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _isObscured,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci la password';
                            }
                            if (value.length < 6) {
                              return 'Minimo 6 caratteri';
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
                          text: 'Password dimenticata?',
                          alignment: Alignment.centerRight,
                          onPressed: () {
                            // TODO
                          },
                        ),
                        const SizedBox(height: 10),
                        BigButton(
                          text: 'Accedi',
                          isLoading: _isLoading,
                          onPressed: _onLoginPressed,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Non hai un account?'),
                    TinyTextButton(
                      text: 'Registrati',
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
