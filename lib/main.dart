
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:ronda_vigilante/screens/auth_check_screen.dart';
import 'package:ronda_vigilante/services/background_service.dart';

void main() async {
  // Garante que os bindings do Flutter estão inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializa o serviço de background
    await BackgroundService.initialize();
    
    // Inicia o aplicativo principal
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Log detalhado do erro
    debugPrint('Erro na inicialização: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Fallback para caso de erro na inicialização
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.grey[100],
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Erro na inicialização',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Não foi possível iniciar o aplicativo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Por favor, reinicie o aplicativo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Tentar reiniciar o aplicativo
                      main();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      'Tentar novamente',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Colors.blueAccent,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: const AuthCheckScreen(),
    );
  }
}