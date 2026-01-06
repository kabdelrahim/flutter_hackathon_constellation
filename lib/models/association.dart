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
  
  // Champs enrichis depuis l'API HuWise
  final String? status; // Active, Dissoute, etc.
  final String? siret; // Numéro SIRET
  final String? socialObjectCode1; // Code objet social primaire
  final String? socialObjectCode2; // Code objet social secondaire
  final String? regionCode; // Code région
  final String? regionName; // Nom région
  final DateTime? updateDate; // Date dernière mise à jour
  final DateTime? dissolutionDate; // Date dissolution si applicable
  
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
    this.status,
    this.siret,
    this.socialObjectCode1,
    this.socialObjectCode2,
    this.regionCode,
    this.regionName,
    this.updateDate,
    this.dissolutionDate,
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
  
  /// Construit une adresse complète à partir des champs granulaires HuWise
  static String _buildFullAddress(Map<String, dynamic> json) {
    final parts = <String>[];
    
    // Construire depuis les champs granulaires
    if (json['street_number_asso'] != null) {
      parts.add(json['street_number_asso'].toString());
    }
    if (json['street_type_asso'] != null) {
      parts.add(json['street_type_asso'].toString());
    }
    if (json['street_name_asso'] != null) {
      parts.add(json['street_name_asso'].toString());
    }
    
    // Fallback sur le champ compilé si disponible
    if (parts.isEmpty && json['comp_address_asso'] != null) {
      parts.add(json['comp_address_asso'].toString());
    }
    
    return parts.join(' ');
  }
  
  /// Convertit un JSON (depuis l'API RNA HuWise) en objet Association
  factory Association.fromRnaJson(Map<String, dynamic> json) {
    final fullAddress = _buildFullAddress(json);
    
    return Association(
      id: json['id'] ?? '',
      nom: json['title'] ?? json['nom'] ?? 'Association sans nom',
      sigle: json['short_title'] ?? json['sigle'],
      objet: json['object'] ?? json['objet'],
      adresse: fullAddress.isNotEmpty ? fullAddress : null,
      codePostal: json['pc_address_asso'] ?? json['adresse_code_postal'],
      ville: json['com_name_asso'] ?? json['adresse_libelle_commune'],
      departement: json['dep_name'] ?? json['dep_code'] ?? json['adresse_code_departement'],
      latitude: json['geo_point_2d'] != null && json['geo_point_2d'] is Map
          ? (json['geo_point_2d']['lat'] as num?)?.toDouble()
          : null,
      longitude: json['geo_point_2d'] != null && json['geo_point_2d'] is Map
          ? (json['geo_point_2d']['lon'] as num?)?.toDouble()
          : null,
      dateCreation: json['creation_date'] != null
          ? DateTime.tryParse(json['creation_date'].toString())
          : null,
      datePublication: json['publication_date'] != null
          ? DateTime.tryParse(json['publication_date'].toString())
          : null,
      status: json['position'],
      siret: json['siret'],
      socialObjectCode1: json['social_object1'],
      socialObjectCode2: json['social_object2'],
      regionCode: json['reg_code'],
      regionName: json['reg_name'],
      updateDate: json['update_date'] != null
          ? DateTime.tryParse(json['update_date'].toString())
          : null,
      dissolutionDate: json['dissolution_date'] != null
          ? DateTime.tryParse(json['dissolution_date'].toString())
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
      status: json['status'],
      siret: json['siret'],
      socialObjectCode1: json['social_object_code1'],
      socialObjectCode2: json['social_object_code2'],
      regionCode: json['region_code'],
      regionName: json['region_name'],
      updateDate: json['update_date'] != null
          ? DateTime.tryParse(json['update_date'])
          : null,
      dissolutionDate: json['dissolution_date'] != null
          ? DateTime.tryParse(json['dissolution_date'])
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
      'status': status,
      'siret': siret,
      'social_object_code1': socialObjectCode1,
      'social_object_code2': socialObjectCode2,
      'region_code': regionCode,
      'region_name': regionName,
      'update_date': updateDate?.toIso8601String(),
      'dissolution_date': dissolutionDate?.toIso8601String(),
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
