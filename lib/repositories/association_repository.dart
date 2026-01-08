import '../models/association.dart';
import '../services/rna_api_service.dart';
import '../services/backend_service.dart';

/// Repository centralisant l'accès aux données des associations
/// Combine les données RNA (OpenData) et backend (enrichies)
class AssociationRepository {
  final RnaApiService rnaApiService;
  final BackendService backendService;
  
  AssociationRepository({
    required this.rnaApiService,
    required this.backendService,
  });
  
  /// Recherche des associations en combinant RNA et données enrichies
  Future<List<Association>> searchAssociations({
    String? query,
    String? ville,
    String? codePostal,
    String? departement,
    String? regionCode,
    bool withCoordinates = false,
    String? status,
    double? minRating,
    int page = 1,
    int perPage = 20,
  }) async {
    // 1. Récupérer les données RNA
    final rnaAssociations = await rnaApiService.searchAssociations(
      query: query,
      ville: ville,
      codePostal: codePostal,
      departement: departement,
      regionCode: regionCode,
      withCoordinates: withCoordinates,
      status: status,
      page: page,
      perPage: perPage,
      includeInactive: status == null, // "Toutes" = inclure inactives
    );
    
    // 2. Enrichir avec les données du backend
    final enrichedAssociations = <Association>[];
    
    for (final rnaAssoc in rnaAssociations) {
      try {
        // Tenter de récupérer les données enrichies
        final enriched = await backendService.getAssociationEnriched(rnaAssoc.id);
        
        if (enriched != null) {
          // Fusionner les données RNA et enrichies
          enrichedAssociations.add(_mergeAssociationData(rnaAssoc, enriched));
        } else {
          // Pas de données enrichies, garder les données RNA telles quelles
          enrichedAssociations.add(Association(
            id: rnaAssoc.id,
            nom: rnaAssoc.nom,
            sigle: rnaAssoc.sigle,
            objet: rnaAssoc.objet,
            adresse: rnaAssoc.adresse,
            codePostal: rnaAssoc.codePostal,
            ville: rnaAssoc.ville,
            departement: rnaAssoc.departement,
            latitude: rnaAssoc.latitude,
            longitude: rnaAssoc.longitude,
            categorie: null,
            dateCreation: rnaAssoc.dateCreation,
            datePublication: rnaAssoc.datePublication,
            status: rnaAssoc.status,
            siret: rnaAssoc.siret,
            socialObjectCode1: rnaAssoc.socialObjectCode1,
            socialObjectCode2: rnaAssoc.socialObjectCode2,
            regionCode: rnaAssoc.regionCode,
            regionName: rnaAssoc.regionName,
            updateDate: rnaAssoc.updateDate,
            dissolutionDate: rnaAssoc.dissolutionDate,
          ));
        }
      } catch (e) {
        // En cas d'erreur, utiliser les données RNA seules
        enrichedAssociations.add(rnaAssoc);
      }
    }
    
    // 3. Filtrer selon les critères
    var filtered = enrichedAssociations;
    
    if (minRating != null) {
      filtered = filtered.where((a) => 
        a.noteGlobale != null && a.noteGlobale! >= minRating
      ).toList();
    }
    
    return filtered;
  }
  
  /// Récupère une association par ID avec toutes ses données
  Future<Association?> getAssociationById(String id) async {
    try {
      // Récupérer les données RNA
      final rnaAssoc = await rnaApiService.getAssociationById(id);
      if (rnaAssoc == null) return null;
      
      // Enrichir avec les données backend
      try {
        final enriched = await backendService.getAssociationEnriched(id);
        if (enriched != null) {
          return _mergeAssociationData(rnaAssoc, enriched);
        }
      } catch (e) {
        // Ignorer les erreurs backend, retourner les données RNA
      }
      
      return rnaAssoc;
    } catch (e) {
      return null;
    }
  }
  
  /// Fusionne les données RNA (OpenData) et les données enrichies par la communauté
  /// Conserve les données officielles RNA (nom, adresse, statut, etc.)
  /// et ajoute les données enrichies (description, notes, photos, revendication, etc.)
  /// @param rna Données officielles depuis le Répertoire National des Associations
  /// @param enriched Données enrichies par la communauté depuis notre backend
  /// @return Association fusionnée avec toutes les informations
  Association _mergeAssociationData(Association rna, Association enriched) {
    return Association(
      id: rna.id,
      nom: rna.nom,
      sigle: rna.sigle,
      objet: rna.objet,
      adresse: rna.adresse,
      codePostal: rna.codePostal,
      ville: rna.ville,
      departement: rna.departement,
      latitude: rna.latitude,
      longitude: rna.longitude,
      categorie: enriched.categorie,
      dateCreation: rna.dateCreation,
      datePublication: rna.datePublication,
      status: rna.status,
      siret: rna.siret,
      socialObjectCode1: rna.socialObjectCode1,
      socialObjectCode2: rna.socialObjectCode2,
      regionCode: rna.regionCode,
      regionName: rna.regionName,
      updateDate: rna.updateDate,
      dissolutionDate: rna.dissolutionDate,
      // Données enrichies
      description: enriched.description,
      siteWeb: enriched.siteWeb,
      email: enriched.email,
      telephone: enriched.telephone,
      logoUrl: enriched.logoUrl,
      photos: enriched.photos,
      noteGlobale: enriched.noteGlobale,
      nombreAvis: enriched.nombreAvis,
      estRevendiquee: enriched.estRevendiquee,
      presidentId: enriched.presidentId,
    );
  }
  
  /// Recherche des associations à proximité d'une position GPS
  /// Combine les données RNA (OpenData) avec les données enrichies du backend
  /// Les résultats sont déjà triés par distance par l'API RNA
  /// @param latitude Latitude du centre de recherche
  /// @param longitude Longitude du centre de recherche
  /// @param radiusKm Rayon de recherche en kilomètres
  /// @return Liste des associations dans le rayon spécifié, enrichies avec les données communautaires
  Future<List<Association>> searchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Récupérer les associations proches via l'API RNA
      final rnaAssociations = await rnaApiService.searchNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      
      // Enrichir avec les données du backend
      final enrichedAssociations = <Association>[];
      
      for (final rnaAssoc in rnaAssociations) {
        try {
          final enriched = await backendService.getAssociationEnriched(rnaAssoc.id);
          if (enriched != null) {
            enrichedAssociations.add(_mergeAssociationData(rnaAssoc, enriched));
          } else {
            enrichedAssociations.add(Association(
              id: rnaAssoc.id,
              nom: rnaAssoc.nom,
              sigle: rnaAssoc.sigle,
              objet: rnaAssoc.objet,
              adresse: rnaAssoc.adresse,
              codePostal: rnaAssoc.codePostal,
              ville: rnaAssoc.ville,
              departement: rnaAssoc.departement,
              latitude: rnaAssoc.latitude,
              longitude: rnaAssoc.longitude,
              categorie: null,
              dateCreation: rnaAssoc.dateCreation,
              datePublication: rnaAssoc.datePublication,
              status: rnaAssoc.status,
              siret: rnaAssoc.siret,
              socialObjectCode1: rnaAssoc.socialObjectCode1,
              socialObjectCode2: rnaAssoc.socialObjectCode2,
              regionCode: rnaAssoc.regionCode,
              regionName: rnaAssoc.regionName,
              updateDate: rnaAssoc.updateDate,
              dissolutionDate: rnaAssoc.dissolutionDate,
            ));
          }
        } catch (e) {
          enrichedAssociations.add(rnaAssoc);
        }
      }
      
      return enrichedAssociations;
    } catch (e) {
      return [];
    }
  }
}
