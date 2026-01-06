/// Modèle représentant une évaluation (note) d'une association par un utilisateur
class Rating {
  final String id;
  final String associationId;
  final String userId;
  final int note; // Note sur 5
  final DateTime dateCreation;
  
  Rating({
    required this.id,
    required this.associationId,
    required this.userId,
    required this.note,
    required this.dateCreation,
  });
  
  /// Convertit un JSON en objet Rating
  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] ?? '',
      associationId: json['association_id'] ?? '',
      userId: json['user_id'] ?? '',
      note: json['note'] ?? 0,
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : DateTime.now(),
    );
  }
  
  /// Convertit l'objet en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'association_id': associationId,
      'user_id': userId,
      'note': note,
      'date_creation': dateCreation.toIso8601String(),
    };
  }
  
  /// Valide que la note est entre 1 et 5
  bool get estValide => note >= 1 && note <= 5;
}

/// Modèle représentant les statistiques de notation d'une association
class RatingStats {
  final String associationId;
  final double noteMoyenne;
  final int nombreNotes;
  final Map<int, int> repartitionNotes; // {1: 5, 2: 3, 3: 10, 4: 20, 5: 15}
  
  RatingStats({
    required this.associationId,
    required this.noteMoyenne,
    required this.nombreNotes,
    required this.repartitionNotes,
  });
  
  /// Convertit un JSON en objet RatingStats
  factory RatingStats.fromJson(Map<String, dynamic> json) {
    return RatingStats(
      associationId: json['association_id'] ?? '',
      noteMoyenne: (json['note_moyenne'] ?? 0.0).toDouble(),
      nombreNotes: json['nombre_notes'] ?? 0,
      repartitionNotes: json['repartition_notes'] != null
          ? Map<int, int>.from(json['repartition_notes'])
          : {},
    );
  }
  
  /// Convertit l'objet en JSON
  Map<String, dynamic> toJson() {
    return {
      'association_id': associationId,
      'note_moyenne': noteMoyenne,
      'nombre_notes': nombreNotes,
      'repartition_notes': repartitionNotes,
    };
  }
  
  /// Calcule le pourcentage d'une note spécifique
  double getPourcentageNote(int note) {
    if (nombreNotes == 0) return 0.0;
    final count = repartitionNotes[note] ?? 0;
    return (count / nombreNotes) * 100;
  }
}
