import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ronda_vigilante/screens/login_screen.dart';
import 'package:ronda_vigilante/screens/rondas_list_screen.dart';
import 'package:ronda_vigilante/services/api_service.dart';
import 'package:ronda_vigilante/services/auth_service.dart';
import 'package:ronda_vigilante/services/background_service.dart';
import 'package:ronda_vigilante/services/local_db_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final LocalDbService _localDbService = LocalDbService();
  final AuthService _authService = AuthService();

  bool _isRondaActive = false;
  Timer? _rondaTimer;
  int? _currentRondaId;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialAuthentication();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (mounted && !results.contains(ConnectivityResult.none)) {
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

  Future<void> _checkInitialAuthentication() async {
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated && mounted) {
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<bool> _checkPermissions() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final newPermission = await Geolocator.requestPermission();
      if (newPermission == LocationPermission.denied ||
          newPermission == LocationPermission.deniedForever) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<bool> _checkAuthentication() async {
    final token = await _authService.getToken();
    if (token == null) {
      return false;
    }
    try {
      return await _apiService.isTokenValid();
    } catch (e) {
      return false;
    }
  }

  Future<void> _startRonda() async {
    if (!mounted) return;

    final hasPermission = await _checkPermissions();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de localização é necessária.')),
      );
      return;
    }

    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      if (!mounted) return;
      _redirectToLogin();
      return;
    }

    if (!mounted) return;
    setState(() { _isRondaActive = true; });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ronda iniciada!')),
    );

    try {
      await _registerPoint();
      _rondaTimer = Timer.periodic(
        const Duration(minutes: 5),
        (timer) => _registerPoint(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar ronda: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _registerPoint() async {
    if (!mounted) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ative o serviço de localização.')),
      );
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final String formattedDate =
          DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());

      if (!mounted) return;

      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);

      if (isOnline) {
        try {
          if (_currentRondaId == null) {
            final rondaData = await _apiService.iniciarRonda(position.latitude, position.longitude);
            _currentRondaId = rondaData['id'];
          } else {
            await _apiService.registrarPonto(_currentRondaId!, position.latitude, position.longitude, formattedDate);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ponto registrado online.'), duration: Duration(seconds: 1)),
            );
          }
        } catch (e) {
          if (_currentRondaId != null) {
            await _localDbService.inserirPontoPendente(_currentRondaId!, position.latitude, position.longitude, formattedDate);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erro na API. Ponto salvo localmente.'), duration: Duration(seconds: 1)),
              );
            }
          }
        }
      } else {
        if (_currentRondaId != null) {
          await _localDbService.inserirPontoPendente(_currentRondaId!, position.latitude, position.longitude, formattedDate);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sem conexão. Ponto salvo localmente.'), duration: Duration(seconds: 1)),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Necessário conexão para iniciar a primeira ronda.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _syncPendingPoints() async {
    if (!mounted) return;

    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      if (!mounted) return;
      _redirectToLogin();
      return;
    }

    final pontosPendentes = await _localDbService.getPontosPendentes();
    if (!mounted || pontosPendentes.isEmpty) return;

    int syncedCount = 0;
    for (final ponto in pontosPendentes) {
      try {
        await _apiService.registrarPonto(ponto['ronda_id'], ponto['latitude'], ponto['longitude'], ponto['data_hora']);
        await _localDbService.deletarPontoPendente(ponto['id']);
        syncedCount++;
      } catch (e) {
        break; 
      }
    }

    if (mounted && syncedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$syncedCount pontos sincronizados com sucesso.')),
      );
    }
  }

  Future<void> _stopRonda() async {
    _rondaTimer?.cancel();
    await BackgroundService.cancelRondaPoints();

    if (_currentRondaId != null) {
      try {
        await _apiService.finalizarRonda(_currentRondaId!);
      } catch (e) { /* Ignorar erro de finalização */ }
    }

    if (!mounted) return;

    setState(() {
      _isRondaActive = false;
      _currentRondaId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ronda finalizada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Controle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _apiService.logout();
              if (mounted) {
                _redirectToLogin();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRondaCard(),
            const SizedBox(height: 20),
            _buildHistoryCard(),
            const SizedBox(height: 20),
            _buildSyncCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRondaCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              _isRondaActive ? Icons.stop_circle : Icons.play_circle_fill,
              size: 50,
              color: _isRondaActive ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 10),
            Text(
              _isRondaActive ? 'Ronda Ativa' : 'Ronda Inativa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRondaActive ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _isRondaActive ? _stopRonda : _startRonda,
              child: Text(
                _isRondaActive ? 'Finalizar Ronda' : 'Iniciar Ronda',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.history, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              'Histórico',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RondasListScreen(),
                  ),
                );
              },
              child: const Text(
                'Ver Rondas Realizadas',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.sync, size: 50, color: Colors.orange),
            const SizedBox(height: 10),
            Text(
              'Sincronização',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _syncPendingPoints,
              child: const Text(
                'Sincronizar Pontos',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}