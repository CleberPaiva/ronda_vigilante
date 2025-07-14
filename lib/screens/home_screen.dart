import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ronda_vigilante/screens/rondas_list_screen.dart';
import 'package:ronda_vigilante/services/api_service.dart';
import 'package:ronda_vigilante/services/local_db_service.dart';
import 'package:ronda_vigilante/services/auth_service.dart';
import 'package:ronda_vigilante/services/background_service.dart';
import 'package:ronda_vigilante/screens/login_screen.dart';

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
    _checkPermissions();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
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

  /// Verificação inicial de autenticação
  Future<void> _checkInitialAuthentication() async {
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      return; // Já redirecionou para login
    }
  }

  /// Redireciona para tela de login
  void _redirectToLogin() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão expirada. Redirecionando para login...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Aguarda um pouco para mostrar a mensagem
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    }
  }

  /// Método aprimorado para verificar permissões
  Future<bool> _checkPermissions() async {
    // Primeira verificação com geolocator
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permissão de localização negada permanentemente.',
            ),
            action: SnackBarAction(
              label: 'Abrir Configurações',
              onPressed: () {
                Geolocator.openAppSettings();
              },
            ),
          ),
        );
      }
      return false;
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização necessária para continuar.'),
          ),
        );
      }
      return false;
    }

    // Verificação adicional com permission_handler
    PermissionStatus status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permissão de localização negada permanentemente.',
            ),
            action: SnackBarAction(
              label: 'Abrir Configurações',
              onPressed: () async {
                await openAppSettings();
              },
            ),
          ),
        );
      }
      return false;
    }
    
    return status.isGranted && (permission == LocationPermission.always || permission == LocationPermission.whileInUse);
  }

  /// Verifica se o usuário está autenticado e redireciona se necessário
  Future<bool> _checkAuthentication() async {
    final token = await _authService.getToken();
    if (token == null) {
      _redirectToLogin();
      return false;
    }
    
    // Verificar se o token é válido
    try {
      final isValid = await _apiService.isTokenValid();
      if (!isValid) {
        _redirectToLogin();
        return false;
      }
    } catch (e) {
      _redirectToLogin();
      return false;
    }
    
    return true;
  }

  /// Método modificado para verificar permissões e autenticação antes de iniciar
  Future<void> _startRonda() async {
    try {
      // Verificar autenticação primeiro
      bool isAuthenticated = await _checkAuthentication();
      if (!isAuthenticated) {
        return; // Já redirecionou para login
      }

      // Verificar permissões
      bool hasPermission = await _checkPermissions();
      if (!hasPermission) {
        return;
      }

      setState(() {
        _isRondaActive = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ronda iniciada!')),
      );

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

  /// Método aprimorado para registrar pontos com verificação completa
  Future<void> _registerPoint() async {
    try {
      // Verificar autenticação
      bool isAuthenticated = await _checkAuthentication();
      if (!isAuthenticated) {
        _stopRonda();
        return; // Já redirecionou para login
      }

      // Verificar permissões
      bool hasPermission = await _checkPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de localização necessária para registrar pontos.'),
            ),
          );
        }
        return;
      }

      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Serviço de localização desabilitado.'),
              action: SnackBarAction(
                label: 'Habilitar',
                onPressed: () {
                  Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'")
          .format(DateTime.now().toUtc());

      var connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = !connectivityResult.contains(ConnectivityResult.none);

      if (isOnline) {
        try {
          if (_currentRondaId == null) {
            final rondaData = await _apiService.iniciarRonda(
              position.latitude,
              position.longitude,
            );
            _currentRondaId = rondaData['id'];
          } else {
            await _apiService.registrarPonto(
              _currentRondaId!,
              position.latitude,
              position.longitude,
              formattedDate,
            );
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Ponto registrado online.'),
              duration: Duration(seconds: 1),
            ));
          }
        } catch (e) {
          if (e.toString().contains('Token de autenticação inválido') ||
              e.toString().contains('Authentication credentials were not provided')) {
            _redirectToLogin();
            _stopRonda();
            return;
          }
          
          // Se houver erro de rede, salvar localmente
          if (_currentRondaId != null) {
            await _localDbService.inserirPontoPendente(
              _currentRondaId!,
              position.latitude,
              position.longitude,
              formattedDate,
            );
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Erro na API. Ponto salvo localmente.'),
                duration: Duration(seconds: 1),
              ));
            }
          }
        }
      } else {
        if (_currentRondaId != null) {
          await _localDbService.inserirPontoPendente(
            _currentRondaId!,
            position.latitude,
            position.longitude,
            formattedDate,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Sem conexão. Ponto salvo localmente.'),
              duration: Duration(seconds: 1),
            ));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Necessário conexão para iniciar a primeira ronda.'),
            ));
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('Token de autenticação inválido') ||
          e.toString().contains('Authentication credentials were not provided')) {
        _redirectToLogin();
        _stopRonda();
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar ponto: ${e.toString()}')),
        );
      }
    }
  }

  /// Implementação completa da sincronização de pontos pendentes
  Future<void> _syncPendingPoints() async {
    try {
      // Verificar autenticação antes de sincronizar
      bool isAuthenticated = await _checkAuthentication();
      if (!isAuthenticated) {
        return; // Já redirecionou para login
      }

      final pontosPendentes = await _localDbService.getPontosPendentes();
      
      if (pontosPendentes.isEmpty) {
        return;
      }

      int syncedCount = 0;
      
      for (final ponto in pontosPendentes) {
        try {
          await _apiService.registrarPonto(
            ponto['ronda_id'],
            ponto['latitude'],
            ponto['longitude'],
            ponto['data_hora'],
          );
          
          // Remover ponto sincronizado do banco local
          await _localDbService.deletarPontoPendente(ponto['id']);
          syncedCount++;
        } catch (e) {
          // Se houver erro de autenticação, parar tentativas
          if (e.toString().contains('Token de autenticação inválido') ||
              e.toString().contains('Authentication credentials were not provided')) {
            break;
          }
          // Continuar tentando outros pontos
        }
      }

      if (mounted && syncedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$syncedCount pontos sincronizados com sucesso.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Sincronização falhou, mas não precisa alertar o usuário
      // Log do erro pode ser útil para debug
    }
  }

  /// Método melhorado para finalizar ronda
  Future<void> _stopRonda() async {
    _rondaTimer?.cancel();
    
    // Cancelar tarefa de background
    await BackgroundService.cancelRondaPoints();
    
    // Tentar finalizar ronda no servidor se houver ID
    if (_currentRondaId != null) {
      try {
        var connectivityResult = await Connectivity().checkConnectivity();
        bool isOnline = !connectivityResult.contains(ConnectivityResult.none);
        
        if (isOnline) {
          await _apiService.finalizarRonda(_currentRondaId!);
        }
      } catch (e) {
        // Falha ao finalizar no servidor não impede finalização local
      }
    }
    
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
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
            Card(
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
                      onPressed: _isRondaActive ? _stopRonda : _startRonda,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRondaActive ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _isRondaActive ? 'Finalizar Ronda' : 'Iniciar Ronda',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
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
                      child: const Text(
                        'Ver Rondas Realizadas',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RondasListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
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
                      child: const Text(
                        'Sincronizar Pontos',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: _syncPendingPoints,
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
