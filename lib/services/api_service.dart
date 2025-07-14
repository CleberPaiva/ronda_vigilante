// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ronda_vigilante/services/auth_service.dart';
import 'package:ronda_vigilante/services/background_service.dart';
import 'package:ronda_vigilante/utils/constants.dart';

class ApiService {
  final AuthService _authService = AuthService();
  
  // Timeout padrão para requisições
  static const Duration _timeout = Duration(seconds: 30);

  /// Obtém headers com token de autenticação
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado. Faça o login novamente.');
    }
    
    // Debug: verificar se o token está sendo recuperado
    print('[DEBUG] Token recuperado: ${token.substring(0, 20)}...');
    
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Token $token', // Testando formato Token
    };
  }

  /// Headers básicos sem autenticação
  Map<String, String> _getBasicHeaders() {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  /// Método para fazer login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/login/'),
        headers: _getBasicHeaders(),
        body: json.encode({'username': username, 'password': password}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        await _authService.saveToken(data['token']);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Credenciais inválidas. Verifique usuário e senha.');
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        throw Exception('Falha no login. Resposta: $errorBody');
      }
    } on SocketException {
      throw Exception('Sem conexão com a internet.');
    } on HttpException {
      throw Exception('Erro na comunicação com o servidor.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: Servidor demorou para responder.');
      }
      throw Exception('Erro no login: ${e.toString()}');
    }
  }

  /// Método para fazer logout
  Future<void> logout() async {
    try {
      final headers = await _getAuthHeaders();
      
      await http.post(
        Uri.parse('$apiBaseUrl/api/logout/'),
        headers: headers,
      ).timeout(_timeout);
      
      await _authService.deleteToken();
    } catch (e) {
      await _authService.deleteToken();
    }
  }

  /// Verifica se o token atual é válido
  Future<bool> isTokenValid() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/auth/verify/'),
        headers: headers,
      ).timeout(_timeout);

      print('[DEBUG] isTokenValid status: ${response.statusCode}');
      print('[DEBUG] isTokenValid body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('[DEBUG] isTokenValid exception: ${e.toString()}');
      return false;
    }
  }

  /// Método para iniciar ronda
  Future<Map<String, dynamic>> iniciarRonda(double latitude, double longitude) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode({
        'latitude': latitude, 
        'longitude': longitude,
        'data_inicio': DateTime.now().toIso8601String(),
      });
      
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/rondas/iniciar/'),
        headers: headers,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 201) {
        final rondaData = json.decode(utf8.decode(response.bodyBytes));
        
        // Agendar registro automático de pontos em background
        if (rondaData['id'] != null) {
          await BackgroundService.scheduleRondaPoints(rondaData['id']);
        }
        
        return rondaData;
      } else if (response.statusCode == 401) {
        await _authService.deleteToken();
        throw Exception('Token de autenticação inválido ou expirado');
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        throw Exception('Falha ao iniciar ronda. Resposta: $errorBody');
      }
    } on SocketException {
      throw Exception('Sem conexão com a internet.');
    } on HttpException {
      throw Exception('Erro na comunicação com o servidor.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: Servidor demorou para responder.');
      }
      if (e.toString().contains('Token de autenticação inválido')) {
        rethrow;
      }
      throw Exception('Erro ao iniciar ronda: ${e.toString()}');
    }
  }

  /// Método para registrar ponto na ronda
  Future<void> registrarPonto(int rondaId, double latitude, double longitude, String dataHora) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'data_hora_registro': dataHora,
      });
      
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/rondas/$rondaId/registrar-ponto/'),
        headers: headers,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode != 201) {
        if (response.statusCode == 401) {
          await _authService.deleteToken();
          throw Exception('Token de autenticação inválido ou expirado');
        }
        final errorBody = utf8.decode(response.bodyBytes);
        throw Exception('Falha ao registrar ponto. Resposta: $errorBody');
      }
    } on SocketException {
      throw Exception('Sem conexão com a internet.');
    } on HttpException {
      throw Exception('Erro na comunicação com o servidor.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: Servidor demorou para responder.');
      }
      if (e.toString().contains('Token de autenticação inválido')) {
        rethrow;
      }
      throw Exception('Erro ao registrar ponto: ${e.toString()}');
    }
  }

  /// Método para finalizar ronda
  Future<void> finalizarRonda(int rondaId) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode({
        'data_fim': DateTime.now().toIso8601String(),
      });
      
      final response = await http.patch(
        Uri.parse('$apiBaseUrl/api/rondas/$rondaId/finalizar/'),
        headers: headers,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          await _authService.deleteToken();
          throw Exception('Token de autenticação inválido ou expirado');
        }
        final errorBody = utf8.decode(response.bodyBytes);
        throw Exception('Falha ao finalizar ronda. Resposta: $errorBody');
      }
    } on SocketException {
      throw Exception('Sem conexão com a internet.');
    } on HttpException {
      throw Exception('Erro na comunicação com o servidor.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: Servidor demorou para responder.');
      }
      if (e.toString().contains('Token de autenticação inválido')) {
        rethrow;
      }
      throw Exception('Erro ao finalizar ronda: ${e.toString()}');
    }
  }

  /// Método para obter lista de rondas
  Future<List<dynamic>> getRondas() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/rondas/'),
        headers: headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 401) {
        await _authService.deleteToken();
        throw Exception('Token de autenticação inválido ou expirado');
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        throw Exception('Falha ao carregar rondas. Resposta: $errorBody');
      }
    } on SocketException {
      throw Exception('Sem conexão com a internet.');
    } on HttpException {
      throw Exception('Erro na comunicação com o servidor.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: Servidor demorou para responder.');
      }
      if (e.toString().contains('Token de autenticação inválido')) {
        rethrow;
      }
      throw Exception('Erro ao carregar rondas: ${e.toString()}');
    }
  }

  /// Método para obter detalhes de uma ronda específica
  Future<Map<String, dynamic>> getRondaDetalhes(int rondaId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/rondas/$rondaId/'),
        headers: headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 401) {
        await _authService.deleteToken();
        throw Exception('Token de autenticação inválido ou expirado');
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        throw Exception('Falha ao carregar detalhes da ronda. Resposta: $errorBody');
      }
    } on SocketException {
      throw Exception('Sem conexão com a internet.');
    } on HttpException {
      throw Exception('Erro na comunicação com o servidor.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: Servidor demorou para responder.');
      }
      if (e.toString().contains('Token de autenticação inválido')) {
        rethrow;
      }
      throw Exception('Erro ao carregar detalhes da ronda: ${e.toString()}');
    }
  }

  /// Método para sincronizar pontos pendentes
  Future<void> sincronizarPontos(List<Map<String, dynamic>> pontosPendentes) async {
    for (final ponto in pontosPendentes) {
      try {
        await registrarPonto(
          ponto['ronda_id'],
          ponto['latitude'],
          ponto['longitude'],
          ponto['data_hora'],
        );
      } catch (e) {
        // Continua tentando sincronizar outros pontos
        continue;
      }
    }
  }
}
