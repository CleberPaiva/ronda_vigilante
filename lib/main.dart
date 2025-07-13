// lib/main.dart

import 'package:flutter/material.dart';
// Importa a nova tela de verificação de autenticação
import 'package:ronda_vigilante/screens/auth_check_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Ronda',
      debugShowCheckedModeBanner: false, // Opcional: remove a faixa de "Debug"
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Altera a tela inicial para ser a tela de verificação
      home: AuthCheckScreen(),
    );
  }
}
