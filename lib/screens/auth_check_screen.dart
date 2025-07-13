// lib/screens/auth_check_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ronda_vigilante/screens/home_screen.dart';
import 'package:ronda_vigilante/screens/login_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  // 1. Adicione um construtor const com a chave (key)
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    // É uma boa prática declarar Durations como const
    await Future.delayed(const Duration(seconds: 1));

    // 2. Verifique se o widget ainda está na árvore de widgets antes de usar seu contexto.
    if (!mounted) return;

    if (token != null) {
      // Supondo que HomeScreen() pode ser const. Se sim, adicione para melhorar a performance.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Supondo que LoginScreen() pode ser const.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. Use const para widgets estáticos para melhorar a performance.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}