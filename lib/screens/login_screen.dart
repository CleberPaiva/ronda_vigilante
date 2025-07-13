// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:ronda_vigilante/screens/home_screen.dart';
import 'package:ronda_vigilante/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  // ✅ 1. Adicionado construtor const com chave (key)
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // A lógica de login e de salvar o token agora está no ApiService
      await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          // ✅ 3. Adicionado 'const' para a HomeScreen
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // O SnackBar aqui não pode ser 'const' porque 'e.toString()' não é uma constante.
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 2. Adicionado 'const' para performance
      appBar: AppBar(title: const Text('Login do Vigilante')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Usuário')),
            const SizedBox(height: 12),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login, child: const Text('Entrar')),
          ],
        ),
      ),
    );
  }
}