import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ronda_vigilante/services/auth_service.dart';
import 'package:ronda_vigilante/utils/constants.dart';

class ApiService {
  final AuthService _authService = AuthService();

  /// Método privado para obter os cabeçalhos com o token de autenticação.
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado. Faça o login novamente.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Token $token', // Ou 'Bearer $token' dependendo da sua API
    };
  }

  /// Realiza o login e salva o token em caso de sucesso.
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/login/'), // Ajuste a URL se necessário
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      await _authService.saveToken(data['token']);
      return data;
    } else {
      throw Exception('Falha no login. Verifique suas credenciais.');
    }
  }

  /// Inicia uma nova ronda no servidor.
  Future<Map<String, dynamic>> iniciarRonda(double latitude, double longitude) async {
    final headers = await _getAuthHeaders();
    final body = json.encode({'latitude': latitude, 'longitude': longitude});
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/rondas/iniciar/'), // Ajuste a URL se necessário
      headers: headers,
      body: body,
    );

    if (response.statusCode == 201) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception('Falha ao iniciar ronda. Resposta: $errorBody');
    }
  }

  /// Registra um novo ponto em uma ronda existente.
  Future<void> registrarPonto(int rondaId, double latitude, double longitude, String dataHora) async {
    final headers = await _getAuthHeaders();
    final body = json.encode({
      'latitude': latitude,
      'longitude': longitude,
      'data_hora_registro': dataHora,
    });
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/rondas/$rondaId/registrar-ponto/'), // Ajuste a URL
      headers: headers,
      body: body,
    );

    if (response.statusCode != 201) {
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception('Falha ao registrar ponto. Resposta: $errorBody');
    }
  }

  /// Busca a lista de rondas realizadas.
  Future<List<dynamic>> getRondas() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$apiBaseUrl/api/rondas/'), // Ajuste a URL se necessário
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception('Falha ao carregar rondas. Resposta: $errorBody');
    }
  }
}