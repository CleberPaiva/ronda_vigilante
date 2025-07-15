// lib/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia a autenticação do usuário, lidando com o armazenamento,
/// recuperação e exclusão do token de autenticação no dispositivo.
class AuthService {
  /// Chave privada e estática usada para salvar e buscar o token de forma consistente.
  static const _tokenKey = 'authToken';
  
  /// Chave adicional para compatibilidade com o BackgroundService
  static const _backgroundTokenKey = 'auth_token';

  /// Salva o token de autenticação no armazenamento local do dispositivo.
  ///
  /// [token] O token recebido da API após o login bem-sucedido.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Salva com a chave principal
    await prefs.setString(_tokenKey, token);
    
    // Salva também para o background service
    await prefs.setString(_backgroundTokenKey, token);
    
    // Debug: verificar se o token foi salvo
    print('[DEBUG] Token salvo: ${token.substring(0, 20)}...');
    print('[DEBUG] Token salvo para background service também');
  }

  /// Busca o token de autenticação que está salvo localmente.
  ///
  /// Retorna o [String] do token se ele existir, ou `null` caso contrário.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Busca o token específico para o background service.
  ///
  /// Retorna o [String] do token se ele existir, ou `null` caso contrário.
  Future<String?> getBackgroundToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundTokenKey);
  }

  /// Remove o token de autenticação do armazenamento local.
  /// Usado para realizar o logout do usuário.
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove ambas as chaves
    await prefs.remove(_tokenKey);
    await prefs.remove(_backgroundTokenKey);
    
    // Remove também a ronda ativa para parar o background
    await prefs.remove('active_ronda_id');
    
    print('[DEBUG] Tokens removidos e ronda ativa cancelada');
  }

  /// Verifica se existe um token válido salvo.
  ///
  /// Retorna `true` se o token existir, `false` caso contrário.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Atualiza o token para o background service quando necessário.
  /// 
  /// Útil para sincronizar tokens entre o app principal e o background.
  Future<void> syncTokenForBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final mainToken = prefs.getString(_tokenKey);
    
    if (mainToken != null) {
      await prefs.setString(_backgroundTokenKey, mainToken);
      print('[DEBUG] Token sincronizado para background service');
    }
  }

  /// Remove apenas o token do background service (para casos específicos).
  Future<void> deleteBackgroundToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backgroundTokenKey);
    print('[DEBUG] Token do background service removido');
  }
}
