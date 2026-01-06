import 'package:flutter/foundation.dart';
import '../models/association.dart';
import '../repositories/association_repository.dart';

/// Contrôleur pour la gestion des associations
/// Gère la recherche, le filtrage et le cache des associations
class AssociationController extends ChangeNotifier {
  final AssociationRepository _repository;

  AssociationController(this._repository);

  List<Association> _associations = [];
  Association? _selectedAssociation;
  bool _isLoading = false;
  String? _errorMessage;

  // Filtres
  String _searchQuery = '';
  String? _selectedCategorie;
  double? _minRating;
  String? _ville;
  String? _codePostal;
  String? _departement;

  // Pagination - supprimé car non utilisé dans le repository
  bool _hasMoreResults = true;

  // Getters
  List<Association> get associations => _associations;
  Association? get selectedAssociation => _selectedAssociation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreResults => _hasMoreResults;

  String get searchQuery => _searchQuery;
  String? get selectedCategorie => _selectedCategorie;
  double? get minRating => _minRating;
  String? get ville => _ville;
  String? get codePostal => _codePostal;
  String? get departement => _departement;

  /// Recherche d'associations avec les filtres actuels
  Future<void> searchAssociations({
    String? query,
    String? categorie,
    double? minRating,
    String? ville,
    String? codePostal,
    String? departement,
    bool resetPage = true,
  }) async {
    if (resetPage) {
      _associations = [];
      _hasMoreResults = true;
    }

    // Mise à jour des filtres
    if (query != null) _searchQuery = query;
    if (categorie != null) _selectedCategorie = categorie;
    if (minRating != null) _minRating = minRating;
    if (ville != null) _ville = ville;
    if (codePostal != null) _codePostal = codePostal;
    if (departement != null) _departement = departement;

    _setLoading(true);
    _clearError();

    try {
      final results = await _repository.searchAssociations(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        ville: _ville,
        codePostal: _codePostal,
        categorie: _selectedCategorie,
        minRating: _minRating,
      );

      if (resetPage) {
        _associations = results;
      } else {
        _associations.addAll(results);
      }

      _hasMoreResults = results.length >= 20; // 20 par page par défaut
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la recherche: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Charge plus de résultats (pagination)
  /// Note: La pagination n'est pas encore implémentée dans le repository
  Future<void> loadMoreResults() async {
    if (!_hasMoreResults || _isLoading) return;

    await searchAssociations(resetPage: false);
  }

  /// Récupère les détails d'une association par ID
  Future<void> getAssociationById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final association = await _repository.getAssociationById(id);
      _selectedAssociation = association;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la récupération: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Sélectionne une association depuis la liste
  void selectAssociation(Association association) {
    _selectedAssociation = association;
    notifyListeners();
  }

  /// Recharge l'association sélectionnée (après mise à jour)
  Future<void> refreshSelectedAssociation() async {
    if (_selectedAssociation == null) return;
    await getAssociationById(_selectedAssociation!.id);
  }

  /// Réinitialise tous les filtres
  void clearFilters() {
    _searchQuery = '';
    _selectedCategorie = null;
    _minRating = null;
    _ville = null;
    _codePostal = null;
    _departement = null;
    notifyListeners();
  }

  /// Applique uniquement les filtres de catégorie et note
  void applyQuickFilters({String? categorie, double? minRating}) {
    _selectedCategorie = categorie;
    _minRating = minRating;
    searchAssociations(resetPage: true);
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
