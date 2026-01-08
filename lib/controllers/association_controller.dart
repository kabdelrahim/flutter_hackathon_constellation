import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/association.dart';
import '../repositories/association_repository.dart';
import '../config/api_config.dart';

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
  double? _minRating;
  String? _ville;
  String? _codePostal;
  String? _departement;
  String? _regionCode;
  bool _withCoordinates = false;
  String? _status;

  // Pagination
  int _currentPage = 1;
  int _pageSize = ApiConfig.defaultPageSize;
  bool _hasMoreResults = true;

  // Etat "recherche effectuée" pour afficher l'état pré-recherche dans la vue
  bool _hasSearched = false;

  // Getters
  List<Association> get associations => _associations;
  Association? get selectedAssociation => _selectedAssociation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreResults => _hasMoreResults;
  bool get hasSearched => _hasSearched;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  String get searchQuery => _searchQuery;
  double? get minRating => _minRating;
  String? get ville => _ville;
  String? get codePostal => _codePostal;
  String? get departement => _departement;
  String? get regionCode => _regionCode;
  bool get withCoordinates => _withCoordinates;
  String? get status => _status;

  /// Recherche d'associations avec les filtres actuels
  /// Permet une recherche multicritères avec pagination
  /// Supporte la recherche textuelle, géographique et par critères administratifs
  /// @param query Terme de recherche textuelle (nom, sigle, objet)
  /// @param minRating Note minimale (filtre sur les données enrichies)
  /// @param ville Filtrer par nom de ville
  /// @param codePostal Filtrer par code postal
  /// @param departement Filtrer par département
  /// @param regionCode Filtrer par code région
  /// @param latitude Latitude pour tri par distance (optionnel)
  /// @param longitude Longitude pour tri par distance (optionnel)
  /// @param maxDistanceKm Distance maximale en km (avec latitude/longitude)
  /// @param withCoordinates Ne retourner que les associations avec coordonnées GPS
  /// @param status Statut de l'association (Active, Dissoute, etc.)
  /// @param resetPage Réinitialiser la pagination (true par défaut)
  Future<void> searchAssociations({
    String? query,
    double? minRating,
    String? ville,
    String? codePostal,
    String? departement,
    String? regionCode,
    double? latitude,
    double? longitude,
    double? maxDistanceKm,
    bool? withCoordinates,
    String? status,
    bool resetPage = true,
  }) async {
    if (resetPage) {
      _associations = [];
      _hasMoreResults = true;
      
      // Réinitialiser les filtres lors d'une nouvelle recherche
      _searchQuery = query ?? '';
      _minRating = minRating;
      _ville = ville;
      _codePostal = codePostal;
      _departement = departement;
      _regionCode = regionCode;
      _withCoordinates = withCoordinates ?? false;
      _status = status;
    } else {
      // Pagination: conserver les filtres existants
      if (query != null) _searchQuery = query;
      if (minRating != null) _minRating = minRating;
      if (ville != null) _ville = ville;
      if (codePostal != null) _codePostal = codePostal;
      if (departement != null) _departement = departement;
      if (regionCode != null) _regionCode = regionCode;
      if (withCoordinates != null) _withCoordinates = withCoordinates;
      if (status != null) _status = status;
    }

    // Marquer que l'utilisateur a lancé une recherche s'il y a un terme ou un filtre
    final hasAnyFilter = (_searchQuery.isNotEmpty) ||
        (_minRating != null) ||
        (_ville != null && _ville!.isNotEmpty) ||
        (_codePostal != null && _codePostal!.isNotEmpty) ||
        (_departement != null && _departement!.isNotEmpty) ||
        (_regionCode != null && _regionCode!.isNotEmpty) ||
        (_withCoordinates) ||
        (_status != null && _status!.isNotEmpty);
    if (hasAnyFilter) {
      _hasSearched = true;
    }

    _setLoading(true);
    _clearError();

    try {
      // Déterminer la page à charger
      final requestedPage = resetPage ? 1 : (_currentPage + 1);

      final results = await _repository.searchAssociations(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        ville: _ville,
        codePostal: _codePostal,
        departement: _departement,
        regionCode: _regionCode,
        withCoordinates: _withCoordinates || (latitude != null && longitude != null),
        status: _status,
        minRating: _minRating,
        page: requestedPage,
        perPage: _pageSize,
      );

      // Tri et filtre distance côté client si coordonnées fournies
      List<Association> list = List<Association>.from(results);
      if (latitude != null && longitude != null) {
        list = list.where((a) => a.hasCoordinates).toList();
        list.sort((a, b) {
          final dA = Geolocator.distanceBetween(latitude, longitude, a.latitude!, a.longitude!);
          final dB = Geolocator.distanceBetween(latitude, longitude, b.latitude!, b.longitude!);
          return dA.compareTo(dB);
        });
        if (maxDistanceKm != null) {
          list = list
              .where((a) =>
                  Geolocator.distanceBetween(latitude, longitude, a.latitude!, a.longitude!) /
                      1000 <=
                  maxDistanceKm)
              .toList();
        }
      }

      if (resetPage) {
        _associations = list;
        _currentPage = 1;
      } else {
        _associations.addAll(list);
        _currentPage = requestedPage;
      }

      _hasMoreResults = results.length >= _pageSize;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la recherche: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Charge plus de résultats (pagination)
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

  /// Recherche des associations autour d'une position géographique donnée
  /// Utilise l'API RNA avec le filtre geofilter.distance pour obtenir
  /// les associations dans un rayon spécifié
  /// @param latitude Latitude de la position de recherche
  /// @param longitude Longitude de la position de recherche
  /// @param radiusKm Rayon de recherche en kilomètres (défaut: 10km)
  Future<void> searchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final results = await _repository.searchNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      
      _associations = results;
      _currentPage = 1;
      _hasMoreResults = false; // Pas de pagination pour les recherches géographiques
      _hasSearched = true;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la recherche géographique: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Réinitialise tous les filtres
  void clearFilters() {
    _searchQuery = '';
    _minRating = null;
    _ville = null;
    _codePostal = null;
    _departement = null;
    _regionCode = null;
    _withCoordinates = false;
    _status = null;
    _associations = [];
    _currentPage = 1;
    _hasMoreResults = true;
    _hasSearched = false;
    notifyListeners();
  }

  /// Applique rapidement un filtre de note
  void applyQuickFilters({double? minRating}) {
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
