// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ronda_vigilante/services/auth_service.dart';
import 'package:ronda_vigilante/utils/constants.dart';

class ApiService {
  final AuthService _authService = AuthService();

  // Método privado para obter os cabeçalhos com o token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      // Se não houver token, a requisição não deve nem ser feita
      throw Exception('Usuário não autenticado.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Token $token',
    };
  }

  // O login é um caso especial, pois não precisa de token
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$API_BASE_URL/api/login/'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Salva o token usando nosso novo serviço
      await _authService.saveToken(data['token']);
      return data;
    } else {
      throw Exception('Falha no login. Verifique suas credenciais.');
    }
  }

  Future<Map<String, dynamic>> iniciarRonda(
      double latitude, double longitude) async {
    final headers = await _getAuthHeaders(); // Usa o método privado
    final body = json.encode({'latitude': latitude, 'longitude': longitude});
    final response = await http.post(
        Uri.parse('$API_BASE_URL/api/rondas/iniciar/'),
        headers: headers,
        body: body);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Falha ao iniciar ronda. Resposta do servidor: ${response.body}');
    }
  }

  Future<void> registrarPonto(
      int rondaId, double latitude, double longitude, String dataHora) async {
    final headers = await _getAuthHeaders();
    final body = json.encode({
      'latitude': latitude,
      'longitude': longitude,
      'data_hora_registro': dataHora,
    });
    final response = await http.post(
        Uri.parse('$API_BASE_URL/api/rondas/$rondaId/registrar-ponto/'),
        headers: headers,
        body: body);

    if (response.statusCode != 201) {
      throw Exception(
          'Falha ao registrar ponto. Resposta do servidor: ${response.body}');
    }
  }

  Future<List<dynamic>> getRondas() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse('$API_BASE_URL/api/rondas/'),
        headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception(
          'Falha ao carregar rondas. Resposta do servidor: ${response.body}');
    }
  }
}
