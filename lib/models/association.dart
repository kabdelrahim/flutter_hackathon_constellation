/// Modèle représentant une association depuis le RNA (Répertoire National des Associations)
/// et les données enrichies par la communauté
class Association {
  final String id; // ID RNA
  final String nom;
  final String? sigle;
  final String? objet; // Description de l'objet de l'association
  final String? adresse;
  final String? codePostal;
  final String? ville;
  final String? departement;
  final double? latitude;
  final double? longitude;
  final String? categorie;
  final DateTime? dateCreation;
  final DateTime? datePublication;
  
  // Données enrichies par la communauté
  final String? description; // Description enrichie par le président
  final String? siteWeb;
  final String? email;
  final String? telephone;
  final String? logoUrl;
  final List<String>? photos;
  final double? noteGlobale; // Note moyenne de la communauté
  final int? nombreAvis; // Nombre d'avis
  final bool estRevendiquee; // Si un président a revendiqué la page
  final String? presidentId; // ID du président si revendiquée
  
  Association({
    required this.id,
    required this.nom,
    this.sigle,
    this.objet,
    this.adresse,
    this.codePostal,
    this.ville,
    this.departement,
    this.latitude,
    this.longitude,
    this.categorie,
    this.dateCreation,
    this.datePublication,
    this.description,
    this.siteWeb,
    this.email,
    this.telephone,
    this.logoUrl,
    this.photos,
    this.noteGlobale,
    this.nombreAvis,
    this.estRevendiquee = false,
    this.presidentId,
  });
  
  /// Convertit un JSON (depuis l'API RNA) en objet Association
  factory Association.fromRnaJson(Map<String, dynamic> json) {
    return Association(
      id: json['id_association'] ?? json['id'] ?? '',
      nom: json['titre'] ?? json['nom'] ?? 'Association sans nom',
      sigle: json['sigle'],
      objet: json['objet'],
      adresse: json['adresse_libelle_voie'],
      codePostal: json['adresse_code_postal'],
      ville: json['adresse_libelle_commune'],
      departement: json['adresse_code_departement'],
      dateCreation: json['date_creation'] != null
          ? DateTime.tryParse(json['date_creation'])
          : null,
      datePublication: json['date_publication'] != null
          ? DateTime.tryParse(json['date_publication'])
          : null,
    );
  }
  
  /// Convertit un JSON enrichi (depuis notre DB) en objet Association
  factory Association.fromJson(Map<String, dynamic> json) {
    return Association(
      id: json['id'] ?? '',
      nom: json['nom'] ?? 'Association sans nom',
      sigle: json['sigle'],
      objet: json['objet'],
      adresse: json['adresse'],
      codePostal: json['code_postal'],
      ville: json['ville'],
      departement: json['departement'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      categorie: json['categorie'],
      dateCreation: json['date_creation'] != null
          ? DateTime.tryParse(json['date_creation'])
          : null,
      datePublication: json['date_publication'] != null
          ? DateTime.tryParse(json['date_publication'])
          : null,
      description: json['description'],
      siteWeb: json['site_web'],
      email: json['email'],
      telephone: json['telephone'],
      logoUrl: json['logo_url'],
      photos: json['photos'] != null 
          ? List<String>.from(json['photos'])
          : null,
      noteGlobale: json['note_globale']?.toDouble(),
      nombreAvis: json['nombre_avis'],
      estRevendiquee: json['est_revendiquee'] ?? false,
      presidentId: json['president_id'],
    );
  }
  
  /// Convertit l'objet en JSON pour l'envoi à l'API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'sigle': sigle,
      'objet': objet,
      'adresse': adresse,
      'code_postal': codePostal,
      'ville': ville,
      'departement': departement,
      'latitude': latitude,
      'longitude': longitude,
      'categorie': categorie,
      'date_creation': dateCreation?.toIso8601String(),
      'date_publication': datePublication?.toIso8601String(),
      'description': description,
      'site_web': siteWeb,
      'email': email,
      'telephone': telephone,
      'logo_url': logoUrl,
      'photos': photos,
      'note_globale': noteGlobale,
      'nombre_avis': nombreAvis,
      'est_revendiquee': estRevendiquee,
      'president_id': presidentId,
    };
  }
  
  /// Retourne l'adresse complète formatée
  String get adresseComplete {
    final parts = <String>[];
    if (adresse != null) parts.add(adresse!);
    if (codePostal != null) parts.add(codePostal!);
    if (ville != null) parts.add(ville!);
    return parts.join(', ');
  }
  
  /// Vérifie si l'association a des coordonnées GPS
  bool get hasCoordinates => latitude != null && longitude != null;
}
