import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

/// Service d'authentification pour le backend Constellation
/// Gère la connexion, l'inscription et la persistance de la session
class AuthService {
  final http.Client _client;
  final SharedPreferences _prefs;
  String? _authToken;
  User? _currentUser;
  
  AuthService({
    required http.Client client,
    required SharedPreferences prefs,
  })  : _client = client,
        _prefs = prefs;
  
  /// Retourne le token d'authentification actuel
  String? get authToken => _authToken;
  
  /// Retourne l'utilisateur actuellement connecté
  User? get currentUser => _currentUser;
  
  /// Vérifie si un utilisateur est connecté
  bool get isAuthenticated => _authToken != null && _currentUser != null;
  
  /// Initialise le service en chargeant la session depuis le stockage local
  Future<void> initialize() async {
    _authToken = _prefs.getString(ApiConfig.authTokenKey);
    
    final userDataJson = _prefs.getString(ApiConfig.userDataKey);
    if (userDataJson != null) {
      try {
        _currentUser = User.fromJson(json.decode(userDataJson));
      } catch (e) {
        // Si les données sont corrompues, on les supprime
        await _clearSession();
      }
    }
    
    // Vérifier que le token est toujours valide
    if (_authToken != null) {
      try {
        await getCurrentUser();
      } catch (e) {
        // Token invalide, on déconnecte l'utilisateur
        await logout();
      }
    }
  }
  
  /// Connexion d'un utilisateur
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.authLoginEndpoint}');
      
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        _authToken = data['token'];
        _currentUser = User.fromJson(data['user']);
        
        // Sauvegarder la session
        await _saveSession();
        
        return _currentUser!;
      } else if (response.statusCode == 401) {
        throw AuthException('Email ou mot de passe incorrect');
      } else {
        throw AuthException('Erreur de connexion: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Erreur de connexion: $e');
    }
  }
  
  /// Inscription d'un nouvel utilisateur
  Future<User> register({
    required String email,
    required String password,
    required String prenom,
    required String nom,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.authRegisterEndpoint}');
      
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
              'prenom': prenom,
              'nom': nom,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        
        _authToken = data['token'];
        _currentUser = User.fromJson(data['user']);
        
        // Sauvegarder la session
        await _saveSession();
        
        return _currentUser!;
      } else if (response.statusCode == 409) {
        throw AuthException('Cet email est déjà utilisé');
      } else {
        throw AuthException('Erreur d\'inscription: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Erreur d\'inscription: $e');
    }
  }
  
  /// Déconnexion de l'utilisateur
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.authLogoutEndpoint}');
        
        // Appel optionnel au backend pour invalider le token
        _client
            .post(
              uri,
              headers: _getAuthHeaders(),
            )
            .timeout(ApiConfig.connectionTimeout)
            .catchError((_) {
          // Ignorer les erreurs de déconnexion côté serveur
          return http.Response('', 200);
        });
      }
    } finally {
      // Nettoyer la session locale dans tous les cas
      await _clearSession();
    }
  }
  
  /// Récupère les informations de l'utilisateur connecté depuis le serveur
  Future<User> getCurrentUser() async {
    if (_authToken == null) {
      throw AuthException('Aucun utilisateur connecté');
    }
    
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.authMeEndpoint}');
      
      final response = await _client
          .get(uri, headers: _getAuthHeaders())
          .timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentUser = User.fromJson(data);
        
        // Mettre à jour le stockage local
        await _prefs.setString(ApiConfig.userDataKey, json.encode(data));
        
        return _currentUser!;
      } else if (response.statusCode == 401) {
        throw AuthException('Session expirée');
      } else {
        throw AuthException('Erreur lors de la récupération du profil');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Erreur de connexion: $e');
    }
  }
  
  /// Sauvegarde la session dans le stockage local
  Future<void> _saveSession() async {
    if (_authToken != null) {
      await _prefs.setString(ApiConfig.authTokenKey, _authToken!);
    }
    
    if (_currentUser != null) {
      await _prefs.setString(
        ApiConfig.userDataKey,
        json.encode(_currentUser!.toJson()),
      );
      await _prefs.setString(ApiConfig.userIdKey, _currentUser!.id);
    }
  }
  
  /// Supprime la session du stockage local
  Future<void> _clearSession() async {
    await _prefs.remove(ApiConfig.authTokenKey);
    await _prefs.remove(ApiConfig.userDataKey);
    await _prefs.remove(ApiConfig.userIdKey);
    
    _authToken = null;
    _currentUser = null;
  }
  
  /// Retourne les headers d'authentification
  Map<String, String> _getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }
  
  /// Retourne les headers d'authentification (méthode publique)
  Map<String, String> getAuthHeaders() => _getAuthHeaders();
  
  void dispose() {
    _client.close();
  }
}

/// Exception personnalisée pour les erreurs d'authentification
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}
