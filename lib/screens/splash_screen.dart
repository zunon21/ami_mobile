import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Attendre 3 secondes pour l'affichage du splash
    await Future.delayed(Duration(seconds: 3));

    // Vérifier si l'utilisateur a déjà vu l'onboarding
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingSeen = prefs.getBool('onboarding_completed') ?? false; // ✅ clé corrigée

    // Vérifier si l'utilisateur est connecté
    final token = await AuthService.getToken();
    final bool isLoggedIn = token != null && await AuthService.isTokenValid();

    if (!onboardingSeen) {
      // Première ouverture → afficher l'onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OnboardingScreen()),
      );
    } else if (isLoggedIn) {
      // Déjà connecté → aller directement à l'accueil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      // Non connecté → aller à l'écran de connexion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        // Plus aucun logo affiché
      ),
    );
  }
}