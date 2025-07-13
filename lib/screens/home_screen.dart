// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ronda_vigilante/screens/rondas_list_screen.dart';
import 'package:ronda_vigilante/services/api_service.dart';
import 'package:ronda_vigilante/services/local_db_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
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
      if (!results.contains(ConnectivityResult.none)) _syncPendingPoints();
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
        .showSnackBar(SnackBar(content: Text('Ronda iniciada!')));
    await _registerPoint();
    _rondaTimer =
        Timer.periodic(Duration(minutes: 5), (timer) => _registerPoint());
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
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Ponto registrado online.'),
              duration: Duration(seconds: 1)));
      } else {
        // OFFLINE
        if (_currentRondaId != null) {
          await _localDbService.inserirPontoPendente(_currentRondaId!,
              position.latitude, position.longitude, formattedDate);
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Sem conexão. Ponto salvo localmente.'),
                duration: Duration(seconds: 1)));
        } else {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text('Necessário conexão para iniciar a primeira ronda.')));
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
    }
  }

  Future<void> _syncPendingPoints() async {
    // ... (O código desta função pode permanecer o mesmo, pois já é robusto)
  }

  void _stopRonda() {
    _rondaTimer?.cancel();
    setState(() {
      _isRondaActive = false;
      _currentRondaId = null;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Ronda finalizada.')));
  }

  Future<void> _checkPermissions() async {
    // ... (O código desta função pode permanecer o mesmo)
  }

  @override
  Widget build(BuildContext context) {
    // O código do build pode permanecer o mesmo
    return Scaffold(
      appBar: AppBar(title: Text('Painel de Controle')),
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
                    SizedBox(height: 10),
                    ElevatedButton(
                      child: Text(
                          _isRondaActive ? 'Finalizar Ronda' : 'Iniciar Ronda'),
                      onPressed: _isRondaActive ? _stopRonda : _startRonda,
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isRondaActive ? Colors.red : Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 50, color: Colors.blue),
                    SizedBox(height: 10),
                    ElevatedButton(
                      child: Text('Ver Rondas Realizadas'),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => RondasListScreen()));
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
