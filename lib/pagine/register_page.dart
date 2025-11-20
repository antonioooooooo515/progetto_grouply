import 'package:flutter/material.dart';

import '../theme_modifier.dart';
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
  bool _isRegistered = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // registrazione finta
    setState(() => _isLoading = false);

    if (!mounted) return;

    setState(() {
      _isRegistered = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registrazione avvenuta con successo'),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = AppTheme.themeMode.value;
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // nessuna freccia indietro
        title: null,
        elevation: 0,
        actions: [
          IconButton(
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
                  title: 'Crea un account',
                  subtitle: 'Registrati per iniziare',
                ),
                const SizedBox(height: 32),

                SoftCard(
                  child: _isRegistered
                      ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 60,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Registrazione avvenuta con successo.\nTi diamo il benvenuto nell\'app Grouply - Team Manager',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 24),
                      BigButton(
                        text: 'Vai alla pagina di login',
                        isLoading: false,
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                                (route) => false,
                          );
                        },
                      ),
                    ],
                  )
                      : Form(
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
                              return 'Inserisci una password';
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
                        const SizedBox(height: 20),

                        SoftInput(
                          controller: _confirmController,
                          label: 'Conferma password',
                          icon: Icons.lock_outline,
                          obscureText: _isObscured,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Conferma la password';
                            }
                            if (value != _passwordController.text) {
                              return 'Le password non coincidono';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        BigButton(
                          text: 'Registrati',
                          isLoading: _isLoading,
                          onPressed: _onRegisterPressed,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Hai già un account?'),
                    TinyTextButton(
                      text: 'Accedi',
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                              (route) => false,
                        );
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
