import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/association.dart';

/// Service pour interagir avec l'API RNA (Répertoire National des Associations)
/// Documentation: https://entreprise.data.gouv.fr/api_doc/rna
class RnaApiService {
  final http.Client _client;
  
  RnaApiService({http.Client? client}) : _client = client ?? http.Client();
  
  /// Recherche des associations selon différents critères
  /// 
  /// Paramètres disponibles:
  /// - [query]: Recherche textuelle (nom, sigle, objet)
  /// - [ville]: Filtrer par ville
  /// - [codePostal]: Filtrer par code postal
  /// - [departement]: Filtrer par département
  /// - [page]: Numéro de page (défaut: 1)
  /// - [perPage]: Résultats par page (défaut: 20, max: 100)
  Future<List<Association>> searchAssociations({
    String? query,
    String? ville,
    String? codePostal,
    String? departement,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      // Construction des paramètres de requête
      final queryParams = <String, String>{};
      
      if (query != null && query.isNotEmpty) {
        queryParams['nom'] = query;
      }
      if (ville != null && ville.isNotEmpty) {
        queryParams['ville'] = ville;
      }
      if (codePostal != null && codePostal.isNotEmpty) {
        queryParams['code_postal'] = codePostal;
      }
      if (departement != null && departement.isNotEmpty) {
        queryParams['departement'] = departement;
      }
      queryParams['page'] = page.toString();
      queryParams['per_page'] = perPage.clamp(1, ApiConfig.maxPageSize).toString();
      
      final uri = Uri.parse('${ApiConfig.rnaBaseUrl}${ApiConfig.rnaSearchEndpoint}')
          .replace(queryParameters: queryParams);
      
      final response = await _client
          .get(uri)
          .timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // L'API RNA retourne les résultats dans un format spécifique
        // Structure: { "association": [...] } ou { "associations": [...] }
        List<dynamic> associationsList = [];
        
        if (data is Map) {
          if (data.containsKey('association')) {
            associationsList = data['association'] is List 
                ? data['association'] 
                : [data['association']];
          } else if (data.containsKey('associations')) {
            associationsList = data['associations'] is List 
                ? data['associations'] 
                : [data['associations']];
          }
        } else if (data is List) {
          associationsList = data;
        }
        
        return associationsList
            .map((json) => Association.fromRnaJson(json))
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
      final uri = Uri.parse(
        '${ApiConfig.rnaBaseUrl}${ApiConfig.rnaAssociationEndpoint}/$id'
      );
      
      final response = await _client
          .get(uri)
          .timeout(ApiConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extraire l'objet association de la réponse
        Map<String, dynamic> associationData;
        if (data is Map && data.containsKey('association')) {
          associationData = Map<String, dynamic>.from(data['association'] as Map);
        } else if (data is Map) {
          associationData = Map<String, dynamic>.from(data);
        } else {
          throw RnaApiException('Format de réponse invalide');
        }
        
        return Association.fromRnaJson(associationData);
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
  /// Note: L'API RNA ne supporte pas directement la recherche géographique
  /// Cette méthode fait une recherche par département puis filtre localement
  Future<List<Association>> searchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    // TODO: Implémenter la recherche géographique
    // Pour l'instant, retourne une liste vide
    // Une implémentation complète nécessiterait de:
    // 1. Déterminer le(s) département(s) proche(s)
    // 2. Faire une recherche par département
    // 3. Filtrer les résultats par distance
    
    return [];
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
