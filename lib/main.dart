// lib/main.dart

import 'package:flutter/material.dart';
import 'package:ronda_vigilante/screens/auth_check_screen.dart';

void main() {
  runApp(const MyApp()); // Adicione const aqui
}

class MyApp extends StatelessWidget {
  // Adicione um construtor const com a chave (key)
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Ronda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Use const no widget `home` para melhor performance
      home: const AuthCheckScreen(),
    );
  }
}