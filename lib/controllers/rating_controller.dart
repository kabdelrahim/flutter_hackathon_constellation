import 'package:flutter/foundation.dart';
import '../models/rating.dart';
import '../services/backend_service.dart';
import '../services/auth_service.dart';

/// Contrôleur pour la gestion des notes
class RatingController extends ChangeNotifier {
  final BackendService _backendService;
  final AuthService _authService;

  RatingController(this._backendService, this._authService);

  Map<String, RatingStats> _statsByAssociation = {};
  Map<String, int?> _userRatingByAssociation = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Récupère les statistiques de notes d'une association
  RatingStats? getStatsForAssociation(String associationId) {
    return _statsByAssociation[associationId];
  }

  /// Récupère la note donnée par l'utilisateur connecté
  int? getUserRatingForAssociation(String associationId) {
    return _userRatingByAssociation[associationId];
  }

  /// Charge les statistiques de notation d'une association
  Future<void> loadRatingStats(String associationId) async {
    _setLoading(true);
    _clearError();

    try {
      final stats = await _backendService.getRatingStats(associationId);
      _statsByAssociation[associationId] = stats;
      
      // Récupère aussi la note de l'utilisateur si connecté
      if (_authService.currentUser != null) {
        await _loadUserRating(associationId);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des notes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Charge la note donnée par l'utilisateur connecté
  Future<void> _loadUserRating(String associationId) async {
    try {
      // TODO: Implémenter un endpoint backend pour récupérer la note de l'utilisateur
      // Pour l'instant, on marque comme non noté
      _userRatingByAssociation[associationId] = null;
    } catch (e) {
      debugPrint('Erreur lors du chargement de la note utilisateur: $e');
    }
  }

  /// Ajoute ou modifie la note de l'utilisateur
  Future<bool> rateAssociation({
    required String associationId,
    required int note,
  }) async {
    if (_authService.currentUser == null) {
      _setError('Vous devez être connecté pour noter');
      return false;
    }

    if (note < 1 || note > 5) {
      _setError('La note doit être entre 1 et 5');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _backendService.rateAssociation(
        associationId: associationId,
        note: note,
      );

      // Met à jour la note locale de l'utilisateur
      _userRatingByAssociation[associationId] = note;

      // Recharge les statistiques pour avoir les données à jour
      await loadRatingStats(associationId);

      return true;
    } catch (e) {
      _setError('Erreur lors de la notation: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Calcule la note moyenne à partir des stats
  double? getAverageRating(String associationId) {
    final stats = _statsByAssociation[associationId];
    if (stats == null || stats.nombreNotes == 0) return null;

    return stats.noteMoyenne;
  }

  /// Vérifie si l'utilisateur a déjà noté cette association
  bool hasUserRated(String associationId) {
    return _userRatingByAssociation[associationId] != null;
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
