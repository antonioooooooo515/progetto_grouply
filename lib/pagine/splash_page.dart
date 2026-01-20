import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

import 'home_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<Offset> _slideUpAnimation;
  late Animation<Offset> _slideDownAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideUpAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -1.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInExpo, // Parte piano, accelera alla fine
    ));

    _slideDownAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, 1.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInExpo,
    ));

    _logoScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.linear),
      ),
    );

    _startAppSequence();
  }

  Future<void> _startAppSequence() async {
    _controller.forward();

    final animationMinTime = Future.delayed(const Duration(milliseconds: 1000));

    final firebaseInit = _initFirebase();

    await Future.wait([animationMinTime, firebaseInit]);

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.of(context).pushReplacement(_createRoute(const HomePage()));
    } else {
      Navigator.of(context).pushReplacement(_createRoute(const LoginPage()));
    }
  }

  //INIZIALIZZAZIONE DI FIREBASE
  Future<void> _initFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint("Errore Firebase: $e");
    }
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
      transitionDuration: Duration.zero,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color curtainColor = Color(0xFFE91E63);
    const Color appBackgroundColor = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: SlideTransition(
              position: _slideUpAnimation,
              child: ClipPath(
                clipper: TopAngledClipper(),
                child: Container(color: curtainColor),
              ),
            ),
          ),

          Positioned.fill(
            child: SlideTransition(
              position: _slideDownAnimation,
              child: ClipPath(
                clipper: BottomAngledClipper(),
                child: Container(color: curtainColor),
              ),
            ),
          ),

          //LOGO
          Center(
            child: FadeTransition(
              opacity: _logoFadeAnimation,
              child: ScaleTransition(
                scale: _logoScaleAnimation,
                child: Image.asset(
                  'lib/assets/logo/logo_nobg.png',
                  width: 140,
                  height: 140,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopAngledClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.45);
    path.lineTo(0, size.height * 0.55);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomAngledClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height * 0.55);
    path.lineTo(size.width, size.height * 0.45);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}