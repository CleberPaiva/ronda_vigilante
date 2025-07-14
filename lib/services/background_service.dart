import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ronda_vigilante/utils/constants.dart';

// Callback que será executado em background
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('[BACKGROUND] Executando tarefa: $task');
      
      switch (task) {
        case 'registerRondaPoint':
          return await _registerRondaPoint();
        default:
          return false;
      }
    } catch (e) {
      print('[BACKGROUND] Erro na tarefa: $e');
      return false;
    }
  });
}

// Função para registrar ponto de ronda em background
Future<bool> _registerRondaPoint() async {
  try {
    // 1. Verificar se há uma ronda ativa
    final prefs = await SharedPreferences.getInstance();
    final rondaId = prefs.getString('active_ronda_id');
    final token = prefs.getString('auth_token');
    
    if (rondaId == null || token == null) {
      print('[BACKGROUND] Nenhuma ronda ativa ou token não encontrado');
      return false;
    }
    
    // 2. Obter localização atual
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    // 3. Enviar ponto para o backend
    final response = await http.post(
      Uri.parse('${apiBaseUrl}/api/rondas/$rondaId/registrar-ponto/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'data_hora_registro': DateTime.now().toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 201) {
      print('[BACKGROUND] Ponto registrado com sucesso: ${position.latitude}, ${position.longitude}');
      return true;
    } else {
      print('[BACKGROUND] Erro ao registrar ponto: ${response.statusCode} - ${response.body}');
      return false;
    }
  } catch (e) {
    print('[BACKGROUND] Erro ao registrar ponto: $e');
    return false;
  }
}

class BackgroundService {
  static const String _rondaTaskName = 'registerRondaPoint';
  
  /// Inicializa o WorkManager
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Remover em produção
    );
  }
  
  /// Agenda o registro periódico de pontos de ronda
  static Future<void> scheduleRondaPoints(int rondaId) async {
    try {
      // Salvar ID da ronda ativa
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_ronda_id', rondaId.toString());
      
      // Cancelar tarefas anteriores
      await Workmanager().cancelAll();
      
      // Agendar nova tarefa a cada 2 minutos
      await Workmanager().registerPeriodicTask(
        _rondaTaskName,
        _rondaTaskName,
        frequency: const Duration(minutes: 2),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'ronda_id': rondaId,
        },
      );
      
      print('[BACKGROUND] Tarefa de ronda agendada para ronda $rondaId');
    } catch (e) {
      print('[BACKGROUND] Erro ao agendar tarefa: $e');
    }
  }
  
  /// Cancela o registro periódico de pontos
  static Future<void> cancelRondaPoints() async {
    try {
      await Workmanager().cancelAll();
      
      // Remover ID da ronda ativa
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_ronda_id');
      
      print('[BACKGROUND] Tarefas de ronda canceladas');
    } catch (e) {
      print('[BACKGROUND] Erro ao cancelar tarefas: $e');
    }
  }
  
  /// Verifica se há uma ronda ativa
  static Future<int?> getActiveRondaId() async {
    final prefs = await SharedPreferences.getInstance();
    final rondaId = prefs.getString('active_ronda_id');
    return rondaId != null ? int.tryParse(rondaId) : null;
  }
} 