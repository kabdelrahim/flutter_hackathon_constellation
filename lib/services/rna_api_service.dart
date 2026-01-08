import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/association.dart';

/// Service pour interagir avec l'API RNA (Répertoire National des Associations)
/// Utilise l'API HuWise (Opendatasoft) avec support ODSQL
/// Documentation: https://hub.huwise.com/api/explore/v2.1/catalog/datasets/ref-france-association-repertoire-national/console
class RnaApiService {
  final http.Client _client;
  
  RnaApiService({http.Client? client}) : _client = client ?? http.Client();
  
  /// Construit une requête ODSQL avec les filtres fournis
  /// ODSQL est le langage de requête de l'API Opendatasoft/HuWise
  /// Génère une clause WHERE avec les conditions appropriées
  /// @return Chaîne de requête ODSQL, ou chaîne vide si aucun filtre
  String _buildOdsqlQuery({
    String? query,
    String? ville,
    String? codePostal,
    String? departement,
    String? regionCode,
    bool withCoordinates = false,
    String? status = 'Active', // Par défaut, filtrer les associations actives
  }) {
    final conditions = <String>[];
    
    // Recherche textuelle sur le titre, le sigle ou l'objet
    if (query != null && query.isNotEmpty) {
      final escapedQuery = query.replaceAll('"', '\\"');
      conditions.add('('
          'title like "%$escapedQuery%" OR '
          'short_title like "%$escapedQuery%" OR '
          'object like "%$escapedQuery%"'
          ')');
    }
    
    // Filtre par ville (recherche partielle, LIKE est insensible à la casse dans ODSQL)
    if (ville != null && ville.isNotEmpty) {
      final escapedVille = ville.replaceAll('"', '\\"');
      conditions.add('com_name_asso like "%$escapedVille%"');
    }
    
    // Filtre par code postal
    if (codePostal != null && codePostal.isNotEmpty) {
      conditions.add('pc_address_asso = "$codePostal"');
    }
    
    // Filtre par département (parenthèses pour éviter les problèmes de priorité avec AND)
    if (departement != null && departement.isNotEmpty) {
      final escapedDep = departement.replaceAll('"', '\\"');
      conditions.add('(dep_code = "$escapedDep" OR dep_name like "%$escapedDep%")');
    }

    // Filtre par région
    if (regionCode != null && regionCode.isNotEmpty) {
      conditions.add('reg_code = "$regionCode"');
    }

    // Filtre pour ne conserver que les associations géolocalisées
    if (withCoordinates) {
      conditions.add('geo_point_2d is not null');
    }
    
    // Filtre par statut (par défaut: associations actives)
    if (status != null && status.isNotEmpty) {
      conditions.add('position = "$status"');
    }
    
    if (conditions.isEmpty) {
      return '';
    }
    
    return conditions.join(' AND ');
  }
  
  /// Recherche des associations selon différents critères en utilisant ODSQL
  /// Interroge l'API HuWise (Opendatasoft) du Répertoire National des Associations
  /// 
  /// Paramètres disponibles:
  /// - [query]: Recherche textuelle (nom, sigle, objet de l'association)
  /// - [ville]: Filtrer par nom de commune
  /// - [codePostal]: Filtrer par code postal
  /// - [departement]: Filtrer par code ou nom de département
  /// - [regionCode]: Filtrer par code région
  /// - [withCoordinates]: Ne retourner que les associations géolocalisées
  /// - [status]: Filtrer par statut (Active, Dissoute, etc.)
  /// - [page]: Numéro de page pour la pagination (défaut: 1)
  /// - [perPage]: Nombre de résultats par page (défaut: 20, max: 100)
  /// - [includeInactive]: Inclure les associations dissoutes (défaut: false)
  /// @return Liste des associations correspondant aux critères
  Future<List<Association>> searchAssociations({
    String? query,
    String? ville,
    String? codePostal,
    String? departement,
    String? regionCode,
    bool withCoordinates = false,
    String? status,
    int page = 1,
    int perPage = 20,
    bool includeInactive = false,
  }) async {
    try {
      // Construire la requête ODSQL
      final effectiveStatus = includeInactive ? null : (status ?? 'Active');
      final where = _buildOdsqlQuery(
        query: query,
        ville: ville,
        codePostal: codePostal,
        departement: departement,
        regionCode: regionCode,
        withCoordinates: withCoordinates,
        status: effectiveStatus,
      );
      
      // Construction des paramètres de requête
      final queryParams = <String, String>{
        'limit': perPage.clamp(1, ApiConfig.maxPageSize).toString(),
        'offset': ((page - 1) * perPage).toString(),
      };
      
      // Ajouter la clause WHERE si des conditions existent
      if (where.isNotEmpty) {
        queryParams['where'] = where;
      }
      
      // Construire l'URI complète
      final uri = Uri.parse('${ApiConfig.rnaBaseUrl}${ApiConfig.rnaSearchEndpoint}')
          .replace(queryParameters: queryParams);
      
      final response = await _client
          .get(uri)
          .timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // L'API HuWise retourne les résultats dans un format spécifique
        // Structure: { "results": [...], "total_count": N }
        List<dynamic> associationsList = [];
        
        if (data is Map && data.containsKey('results')) {
          associationsList = (data['results'] as List?) ?? [];
        }
        
        return associationsList
            .map((json) => Association.fromRnaJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        // Aucun résultat trouvé
        return [];
      } else {
        throw RnaApiException(
          'Erreur lors de la recherche: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is RnaApiException) rethrow;
      throw RnaApiException('Erreur de connexion à l\'API RNA: $e');
    }
  }
  
  /// Récupère les détails d'une association par son identifiant RNA
  Future<Association?> getAssociationById(String id) async {
    try {
      final where = 'id = "$id"';
      final queryParams = <String, String>{
        'where': where,
        'limit': '1',
      };
      
      final uri = Uri.parse('${ApiConfig.rnaBaseUrl}${ApiConfig.rnaSearchEndpoint}')
          .replace(queryParameters: queryParams);
      
      final response = await _client
          .get(uri)
          .timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map && data.containsKey('results')) {
          final results = (data['results'] as List?) ?? [];
          if (results.isNotEmpty) {
            return Association.fromRnaJson(results.first as Map<String, dynamic>);
          }
        }
        
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw RnaApiException(
          'Erreur lors de la récupération: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is RnaApiException) rethrow;
      throw RnaApiException('Erreur de connexion à l\'API RNA: $e');
    }
  }
  
  /// Recherche des associations autour d'une position géographique
  /// Utilise la requête géospatiale ODSQL: geo_distance("geo_point_2d", lat, lon, "radius")
  Future<List<Association>> searchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int perPage = 20,
    bool includeInactive = false,
  }) async {
    try {
      // Construire les paramètres de requête avec geofilter.distance
      final radiusMeters = (radiusKm * 1000).toInt();
      
      final queryParams = <String, String>{
        'geofilter.distance': '$latitude,$longitude,$radiusMeters',
        'limit': perPage.clamp(1, ApiConfig.maxPageSize).toString(),
        'offset': '0',
      };
      
      // Ajouter le filtre de statut si nécessaire
      if (!includeInactive) {
        queryParams['where'] = 'position = "Active"';
      }
      
      final uri = Uri.parse('${ApiConfig.rnaBaseUrl}${ApiConfig.rnaSearchEndpoint}')
          .replace(queryParameters: queryParams);
    
      final response = await _client
          .get(uri)
          .timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> associationsList = [];
        if (data is Map && data.containsKey('results')) {
          associationsList = (data['results'] as List?) ?? [];
        }
        
        final results = associationsList
            .map((json) => Association.fromRnaJson(json as Map<String, dynamic>))
            .toList();
        
        return results;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw RnaApiException(
          'Erreur lors de la recherche géographique: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is RnaApiException) rethrow;
      throw RnaApiException('Erreur de connexion à l\'API RNA (recherche géographique): $e');
    }
  }
  
  /// Calcule la distance en kilomètres entre deux points GPS
  /// Utilise la formule de Haversine pour calculer la distance sur une sphère
  /// @param lat1 Latitude du premier point
  /// @param lon1 Longitude du premier point
  /// @param lat2 Latitude du second point
  /// @param lon2 Longitude du second point
  /// @return La distance en kilomètres
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
        cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) *
        sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
  
  /// Convertit des degrés en radians
  /// @param degrees Angle en degrés
  /// @return Angle en radians
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  void dispose() {
    _client.close();
  }
}

/// Exception personnalisée pour les erreurs de l'API RNA
class RnaApiException implements Exception {
  final String message;
  final int? statusCode;
  
  RnaApiException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'RnaApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
