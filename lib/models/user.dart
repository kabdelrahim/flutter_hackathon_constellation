/// Modèle représentant un utilisateur de la plateforme Constellation
class User {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String? avatarUrl;
  final String? ville;
  final String? biographie;
  final DateTime dateInscription;
  final bool estPresident; // Si l'utilisateur est président d'une ou plusieurs associations
  final List<String>? associationsRevendiquees; // IDs des associations revendiquées
  final List<String>? associationsSuivies; // IDs des associations suivies
  
  User({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    this.avatarUrl,
    this.ville,
    this.biographie,
    required this.dateInscription,
    this.estPresident = false,
    this.associationsRevendiquees,
    this.associationsSuivies,
  });
  
  /// Convertit un JSON en objet User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      avatarUrl: json['avatar_url'],
      ville: json['ville'],
      biographie: json['biographie'],
      dateInscription: json['date_inscription'] != null
          ? DateTime.parse(json['date_inscription'])
          : DateTime.now(),
      estPresident: json['est_president'] ?? false,
      associationsRevendiquees: json['associations_revendiquees'] != null
          ? List<String>.from(json['associations_revendiquees'])
          : null,
      associationsSuivies: json['associations_suivies'] != null
          ? List<String>.from(json['associations_suivies'])
          : null,
    );
  }
  
  /// Convertit l'objet en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'avatar_url': avatarUrl,
      'ville': ville,
      'biographie': biographie,
      'date_inscription': dateInscription.toIso8601String(),
      'est_president': estPresident,
      'associations_revendiquees': associationsRevendiquees,
      'associations_suivies': associationsSuivies,
    };
  }
  
  /// Retourne le nom complet de l'utilisateur
  String get nomComplet => '$prenom $nom';
  
  /// Retourne le nombre d'associations revendiquées
  int get nombreAssociationsRevendiquees => associationsRevendiquees?.length ?? 0;
  
  /// Retourne le nombre d'associations suivies
  int get nombreAssociationsSuivies => associationsSuivies?.length ?? 0;
}
