// lib/services/background_service.dart

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
    print('[BACKGROUND] === INICIANDO REGISTRO DE PONTO ===');
    
    final prefs = await SharedPreferences.getInstance();
    final rondaId = prefs.getString('active_ronda_id');
    final token = prefs.getString('auth_token');
    
    print('[BACKGROUND] RondaId: $rondaId');
    print('[BACKGROUND] Token presente: ${token != null}');
    
    if (rondaId == null || token == null) {
      print('[BACKGROUND] ❌ Faltam dados: RondaId=$rondaId, Token=${token != null}');
      return false;
    }
    
    print('[BACKGROUND] 📍 Obtendo localização...');
    
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    print('[BACKGROUND] 📍 Localização obtida: ${position.latitude}, ${position.longitude}');
    
    // Sempre enviar data_hora_registro (obrigatório)
    final now = DateTime.now();
    
    print('[BACKGROUND] 🌐 Enviando para servidor...');
    
    final response = await http.post(
      Uri.parse('${apiBaseUrl}/api/rondas/$rondaId/registrar-ponto/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'data_hora_registro': now.toIso8601String(),
      }),
    ).timeout(const Duration(seconds: 30));
    
    print('[BACKGROUND] 🌐 Resposta do servidor: ${response.statusCode}');
    
    if (response.statusCode == 201) {
      print('[BACKGROUND] ✅ Ponto registrado com sucesso!');
      print('[BACKGROUND] Coordenadas: ${position.latitude}, ${position.longitude}');
      print('[BACKGROUND] Horário: ${now.toIso8601String()}');
      return true;
    } else {
      print('[BACKGROUND] ❌ Erro: ${response.statusCode} - ${response.body}');
      return false;
    }
  } catch (e) {
    print('[BACKGROUND] ❌ Exceção: $e');
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
      print('[BACKGROUND] Configurando agendamento para ronda $rondaId');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_ronda_id', rondaId.toString());
      
      // Sincronizar token do AuthService para o background
      final authToken = prefs.getString('authToken');
      if (authToken != null) {
        await prefs.setString('auth_token', authToken);
        print('[BACKGROUND] Token sincronizado para background service');
      } else {
        print('[BACKGROUND] ⚠️ Token não encontrado no AuthService');
      }
      
      await Workmanager().cancelAll();
      
      // Agendar nova tarefa a cada 3 minutos
      await Workmanager().registerPeriodicTask(
        _rondaTaskName,
        _rondaTaskName,
        frequency: const Duration(minutes: 3),
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
      
      print('[BACKGROUND] ✅ Tarefa de ronda agendada para ronda $rondaId a cada 3 minutos');
    } catch (e) {
      print('[BACKGROUND] ❌ Erro ao agendar tarefa: $e');
    }
  }
  
  /// Cancela o registro periódico de pontos
  static Future<void> cancelRondaPoints() async {
    try {
      await Workmanager().cancelAll();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_ronda_id');
      await prefs.remove('auth_token');
      
      print('[BACKGROUND] ✅ Tarefas de ronda canceladas');
    } catch (e) {
      print('[BACKGROUND] ❌ Erro ao cancelar tarefas: $e');
    }
  }
  
  /// Verifica se há uma ronda ativa
  static Future<int?> getActiveRondaId() async {
    final prefs = await SharedPreferences.getInstance();
    final rondaId = prefs.getString('active_ronda_id');
    return rondaId != null ? int.tryParse(rondaId) : null;
  }
  
  /// Método para testar o registro manual
  static Future<bool> testBackgroundTask() async {
    try {
      print('[TEST] 🧪 Executando teste manual do background...');
      final result = await _registerRondaPoint();
      print('[TEST] 🧪 Resultado: $result');
      return result;
    } catch (e) {
      print('[TEST] ❌ Erro no teste: $e');
      return false;
    }
  }
  
  /// Verifica se o token está sincronizado
  static Future<bool> isTokenSynced() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    final backgroundToken = prefs.getString('auth_token');
    
    print('[BACKGROUND] AuthToken presente: ${authToken != null}');
    print('[BACKGROUND] BackgroundToken presente: ${backgroundToken != null}');
    print('[BACKGROUND] Tokens sincronizados: ${authToken == backgroundToken}');
    
    return authToken != null && backgroundToken != null && authToken == backgroundToken;
  }
  
  /// Força a sincronização do token
  static Future<void> forceTokenSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken');
      
      if (authToken != null) {
        await prefs.setString('auth_token', authToken);
        print('[BACKGROUND] ✅ Token sincronizado forçadamente');
      } else {
        print('[BACKGROUND] ❌ Nenhum token encontrado para sincronizar');
      }
    } catch (e) {
      print('[BACKGROUND] ❌ Erro ao sincronizar token: $e');
    }
  }
  
  /// Verifica o status do background service
  static Future<Map<String, dynamic>> getBackgroundStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final rondaId = prefs.getString('active_ronda_id');
    final authToken = prefs.getString('authToken');
    final backgroundToken = prefs.getString('auth_token');
    
    return {
      'ronda_ativa': rondaId != null,
      'ronda_id': rondaId,
      'auth_token_presente': authToken != null,
      'background_token_presente': backgroundToken != null,
      'tokens_sincronizados': authToken == backgroundToken,
    };
  }
}
