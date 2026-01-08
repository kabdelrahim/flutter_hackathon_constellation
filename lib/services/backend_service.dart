import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/association.dart';
import '../models/comment.dart';
import '../models/rating.dart';
import 'auth_service.dart';

/// Service pour interagir avec le backend Constellation
/// Gère les données enrichies (commentaires, notes, revendications)
class BackendService {
  final http.Client _client;
  final AuthService authService;

  BackendService({
    required this.authService,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // === ASSOCIATIONS ===

  /// Récupère les données enrichies d'une association
  Future<Association?> getAssociationEnriched(String id) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.associationsEndpoint}/$id');
      final response = await _client.get(uri).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Association.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw BackendException('Erreur: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Erreur: $e');
    }
  }

  /// Met à jour une association (président uniquement)
  Future<Association> updateAssociation(String id, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.associationsEndpoint}/$id');
      final response = await _client.put(
        uri,
        headers: authService.getAuthHeaders(),
        body: json.encode(data),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        return Association.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw BackendException('Non autorisé', 401);
      } else {
        throw BackendException('Erreur: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Erreur: $e');
    }
  }

  // === COMMENTAIRES ===

  /// Récupère les commentaires d'une association
  Future<List<Comment>> getComments(String associationId) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.commentsEndpoint}')
          .replace(queryParameters: {'association_id': associationId});

      final response = await _client.get(uri).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw BackendException('Erreur: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Erreur: $e');
    }
  }

  /// Ajoute un commentaire
  Future<Comment> addComment({
    required String associationId,
    required String contenu,
    int? note,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.commentsEndpoint}');
      final response = await _client.post(
        uri,
        headers: authService.getAuthHeaders(),
        body: json.encode({
          'association_id': associationId,
          'contenu': contenu,
          if (note != null) 'note': note,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 201) {
        return Comment.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw BackendException('Vous devez être connecté', 401);
      } else {
        throw BackendException('Erreur: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Erreur: $e');
    }
  }

  /// Supprime un commentaire
  Future<void> deleteComment(String commentId) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.commentsEndpoint}/$commentId');
      final response = await _client.delete(
        uri,
        headers: authService.getAuthHeaders(),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw BackendException('Erreur: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Erreur: $e');
    }
  }

  // === NOTES/RATINGS ===

  /// Récupère les statistiques de notation d'une association
  Future<RatingStats> getRatingStats(String associationId) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.ratingsEndpoint}/stats/$associationId');
      final response = await _client.get(uri).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        return RatingStats.fromJson(json.decode(response.body));
      } else {
        throw BackendException('Erreur: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Erreur: $e');
    }
  }

  /// Ajoute ou met à jour une note
  Future<Rating> rateAssociation({
    required String associationId,
    required int note,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.ratingsEndpoint}');
      final response = await _client.post(
        uri,
        headers: authService.getAuthHeaders(),
        body: json.encode({
          'association_id': associationId,
          'note': note,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Rating.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        throw BackendException('Vous devez être connecté', 401);
      } else {
        throw BackendException('Erreur: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Erreur: $e');
    }
  }

  // === REVENDICATIONS ===

  /// Revendique une association (président)
  Future<void> claimAssociation({
    required String associationId,
    String? justification,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.backendBaseUrl}${ApiConfig.claimsEndpoint}');
      final response = await _client.post(
        uri,
        headers: authService.getAuthHeaders(),
        body: json.encode({
          'association_id': associationId,
          if (justification != null) 'justification': justification,
        }),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode != 201 && response.statusCode != 200) {
        if (response.statusCode == 401) {
          throw BackendException('Vous devez être connecté', 401);
        } else {
          throw BackendException('Erreur: ${response.statusCode}', response.statusCode);
        }
      }
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException('Erreur: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Exception personnalisée pour les erreurs du backend
class BackendException implements Exception {
  final String message;
  final int? statusCode;
  
  BackendException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'BackendException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}
