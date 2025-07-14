
// lib/auth_service.dart


import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia a autenticação do usuário, lidando com o armazenamento,
/// recuperação e exclusão do token de autenticação no dispositivo.
class AuthService {
  /// Chave privada e estática usada para salvar e buscar o token de forma consistente.
  static const _tokenKey = 'authToken';

  /// Salva o token de autenticação no armazenamento local do dispositivo.
  ///
  /// [token] O token recebido da API após o login bem-sucedido.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    // Debug: verificar se o token foi salvo
    print('[DEBUG] Token salvo: ${token.substring(0, 20)}...');
  }

  /// Busca o token de autenticação que está salvo localmente.
  ///
  /// Retorna o [String] do token se ele existir, ou `null` caso contrário.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Remove o token de autenticação do armazenamento local.
  /// Usado para realizar o logout do usuário.
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}