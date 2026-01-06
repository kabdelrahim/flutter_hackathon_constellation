/// Modèle représentant un commentaire laissé par un utilisateur sur une association
class Comment {
  final String id;
  final String associationId;
  final String userId;
  final String userName; // Nom affiché de l'utilisateur
  final String? userAvatarUrl;
  final String contenu;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final int? note; // Note sur 5 associée au commentaire (optionnel)
  
  Comment({
    required this.id,
    required this.associationId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.contenu,
    required this.dateCreation,
    this.dateModification,
    this.note,
  });
  
  /// Convertit un JSON en objet Comment
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      associationId: json['association_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'Utilisateur',
      userAvatarUrl: json['user_avatar_url'],
      contenu: json['contenu'] ?? '',
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : DateTime.now(),
      dateModification: json['date_modification'] != null
          ? DateTime.tryParse(json['date_modification'])
          : null,
      note: json['note'],
    );
  }
  
  /// Convertit l'objet en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'association_id': associationId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'contenu': contenu,
      'date_creation': dateCreation.toIso8601String(),
      'date_modification': dateModification?.toIso8601String(),
      'note': note,
    };
  }
  
  /// Vérifie si le commentaire a été modifié
  bool get estModifie => dateModification != null;
  
  /// Vérifie si le commentaire contient une note
  bool get aUneNote => note != null;
}
