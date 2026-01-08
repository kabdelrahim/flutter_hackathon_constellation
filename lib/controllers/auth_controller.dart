import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Contrôleur pour la gestion de l'authentification utilisateur
/// Gère la connexion, l'inscription, la déconnexion et la restauration de session
/// Utilise Provider pour notifier les changements d'état à l'interface
class AuthController extends ChangeNotifier {
  final AuthService _authService;

  AuthController(this._authService) {
    _init();
  }

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  /// Initialise le contrôleur et restaure la session
  Future<void> _init() async {
    await _authService.initialize();
    _currentUser = _authService.currentUser;
    _isInitialized = true;
    notifyListeners();
  }

  /// Connecte un utilisateur avec son email et mot de passe
  /// Met à jour l'état du contrôleur et notifie les écouteurs
  /// @param email Adresse email de l'utilisateur
  /// @param password Mot de passe de l'utilisateur
  /// @return true si la connexion réussit, false sinon
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Erreur de connexion: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Inscription utilisateur
  Future<bool> register({
    required String email,
    required String password,
    required String prenom,
    required String nom,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        prenom: prenom,
        nom: nom,
      );
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Erreur d\'inscription: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Rafraîchit les informations de l'utilisateur connecté
  Future<void> refreshCurrentUser() async {
    if (!isAuthenticated) return;

    try {
      final user = await _authService.getCurrentUser();
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du profil: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Efface le message d'erreur actuel
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
