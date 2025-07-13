// lib/screens/auth_check_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ronda_vigilante/screens/home_screen.dart';
import 'package:ronda_vigilante/screens/login_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
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

    // Aguarda um instante para a transição de tela ser mais suave
    await Future.delayed(Duration(seconds: 1));

    if (token != null) {
      // Se encontrou um token, vai direto para a tela principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      // Se não encontrou, vai para a tela de login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Exibe uma tela de carregamento enquanto verifica o token
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
