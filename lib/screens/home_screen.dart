// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ronda_vigilante/screens/rondas_list_screen.dart';
import 'package:ronda_vigilante/services/api_service.dart';
import 'package:ronda_vigilante/services/local_db_service.dart';

// ✅ 1. Adicionado construtor com chave (key) para o widget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final LocalDbService _localDbService = LocalDbService();

  bool _isRondaActive = false;
  Timer? _rondaTimer;
  int? _currentRondaId;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      // ✅ 3. Adicionadas chaves ao 'if'
      if (!results.contains(ConnectivityResult.none)) {
        _syncPendingPoints();
      }
    });
  }

  @override
  void dispose() {
    _rondaTimer?.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _startRonda() async {
    setState(() {
      _isRondaActive = true;
    });
    ScaffoldMessenger.of(context)
        // ✅ 2. Adicionado 'const' para performance
        .showSnackBar(const SnackBar(content: Text('Ronda iniciada!')));
    await _registerPoint();
    _rondaTimer =
        Timer.periodic(const Duration(minutes: 5), (timer) => _registerPoint());
  }

  Future<void> _registerPoint() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      String formattedDate =
          DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());

      var connectivityResult = await (Connectivity().checkConnectivity());
      bool isOnline = !connectivityResult.contains(ConnectivityResult.none);

      if (isOnline) {
        if (_currentRondaId == null) {
          final rondaData = await _apiService.iniciarRonda(
              position.latitude, position.longitude);
          _currentRondaId = rondaData['id'];
        } else {
          await _apiService.registrarPonto(_currentRondaId!, position.latitude,
              position.longitude, formattedDate);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ponto registrado online.'),
            duration: Duration(seconds: 1),
          ));
        }
      } else {
        if (_currentRondaId != null) {
          await _localDbService.inserirPontoPendente(_currentRondaId!,
              position.latitude, position.longitude, formattedDate);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Sem conexão. Ponto salvo localmente.'),
              duration: Duration(seconds: 1),
            ));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:
                    Text('Necessário conexão para iniciar a primeira ronda.')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    }
  }

  Future<void> _syncPendingPoints() async {
    // ... (O código desta função pode permanecer o mesmo)
  }

  void _stopRonda() {
    _rondaTimer?.cancel();
    setState(() {
      _isRondaActive = false;
      _currentRondaId = null;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Ronda finalizada.')));
  }

  Future<void> _checkPermissions() async {
    // ... (O código desta função pode permanecer o mesmo)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel de Controle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.play_circle_fill,
                        size: 50,
                        color: _isRondaActive ? Colors.grey : Colors.green),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isRondaActive ? _stopRonda : _startRonda,
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isRondaActive ? Colors.red : Colors.green),
                      child: Text(
                          _isRondaActive ? 'Finalizar Ronda' : 'Iniciar Ronda'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.history, size: 50, color: Colors.blue),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      child: const Text('Ver Rondas Realizadas'),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          // Adicione `const` aqui se `RondasListScreen` tiver um construtor const.
                          builder: (_) => const RondasListScreen(),
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}