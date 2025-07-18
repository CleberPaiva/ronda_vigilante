
// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:ronda_vigilante/screens/home_screen.dart';
import 'package:ronda_vigilante/services/api_service.dart';
import 'package:ronda_vigilante/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
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
    // Garante que o método não prossiga se o widget for removido
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      final token = await AuthService().getToken();
      print('[DEBUG] Token salvo após login: $token');

      // Checagem de segurança após a operação assíncrona
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      // Checagem de segurança após a operação assíncrona
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      // Checagem de segurança para garantir que o estado só seja atualizado se o widget existir
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login do Vigilante')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Usuário'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    // ✅ CORREÇÃO: Argumento 'child' movido para o final
                    child: const Text('Entrar'),
                  ),
          ],
        ),
      ),
    );
  }
}