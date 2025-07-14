// lib/main.dart

import 'package:flutter/material.dart';
import 'package:ronda_vigilante/screens/auth_check_screen.dart';
import 'package:ronda_vigilante/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar o WorkManager
  await BackgroundService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
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
      home: const AuthCheckScreen(),
    );
  }
}