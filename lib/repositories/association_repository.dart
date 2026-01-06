import '../models/association.dart';
import '../services/rna_api_service.dart';
import '../services/backend_service.dart';
import '../config/api_config.dart';

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
    String? categorie,
    double? minRating,
  }) async {
    // 1. Récupérer les données RNA
    final rnaAssociations = await rnaApiService.searchAssociations(
      query: query,
      ville: ville,
      codePostal: codePostal,
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
          // Pas de données enrichies, détecter la catégorie
          final category = AssociationCategories.detectCategory(rnaAssoc.objet);
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
            categorie: category,
            dateCreation: rnaAssoc.dateCreation,
            datePublication: rnaAssoc.datePublication,
          ));
        }
      } catch (e) {
        // En cas d'erreur, utiliser les données RNA seules
        enrichedAssociations.add(rnaAssoc);
      }
    }
    
    // 3. Filtrer selon les critères
    var filtered = enrichedAssociations;
    
    if (categorie != null) {
      filtered = filtered.where((a) => a.categorie == categorie).toList();
    }
    
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
  
  /// Fusionne les données RNA et enrichies
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
      categorie: enriched.categorie ?? AssociationCategories.detectCategory(rna.objet),
      dateCreation: rna.dateCreation,
      datePublication: rna.datePublication,
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
}
