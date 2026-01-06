/// Configuration des endpoints de l'API RNA (Répertoire National des Associations)
/// et de l'API backend Constellation
class ApiConfig {
  // API RNA - OpenData du gouvernement
  // Documentation: https://entreprise.data.gouv.fr/api_doc/rna
  static const String rnaBaseUrl = 'https://entreprise.data.gouv.fr/api/rna/v1';
  
  // Endpoints RNA
  static const String rnaSearchEndpoint = '/rechercher';
  static const String rnaAssociationEndpoint = '/id';
  
  // TODO: Remplacer par l'URL de votre backend
  // Pour le développement local, utiliser l'émulateur Android: http://10.0.2.2:3000
  // Pour iOS: http://localhost:3000
  static const String backendBaseUrl = 'http://localhost:3000/api';
  
  // Endpoints Backend Constellation
  static const String authLoginEndpoint = '/auth/login';
  static const String authRegisterEndpoint = '/auth/register';
  static const String authLogoutEndpoint = '/auth/logout';
  static const String authMeEndpoint = '/auth/me';
  
  static const String usersEndpoint = '/users';
  static const String associationsEndpoint = '/associations';
  static const String commentsEndpoint = '/comments';
  static const String ratingsEndpoint = '/ratings';
  static const String claimsEndpoint = '/claims'; // Revendications
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Paramètres de pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Clés de stockage local
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
}

/// Catégories d'associations reconnues par l'application
class AssociationCategories {
  static const List<String> all = [
    'Sport',
    'Culture',
    'Social',
    'Environnement',
    'Éducation',
    'Santé',
    'Loisirs',
    'Défense des droits',
    'Religion',
    'Autres',
  ];
  
  /// Retourne la catégorie correspondant à l'objet de l'association (heuristique)
  static String? detectCategory(String? objet) {
    if (objet == null) return null;
    
    final objetLower = objet.toLowerCase();
    
    if (objetLower.contains(RegExp(r'sport|football|basket|tennis|athlétisme|natation'))) {
      return 'Sport';
    }
    
    if (objetLower.contains(RegExp(r'culture|art|musique|théâtre|cinéma|danse'))) {
      return 'Culture';
    }
    
    if (objetLower.contains(RegExp(r'social|solidarité|aide|entraide|humanitaire'))) {
      return 'Social';
    }
    
    if (objetLower.contains(RegExp(r'environnement|écologie|nature|biodiversité|climat'))) {
      return 'Environnement';
    }
    
    if (objetLower.contains(RegExp(r'éducation|enseignement|formation|école|pédagogie'))) {
      return 'Éducation';
    }
    
    if (objetLower.contains(RegExp(r'santé|médical|soin|bien-être'))) {
      return 'Santé';
    }
    
    if (objetLower.contains(RegExp(r'loisir|jeu|divertissement|hobby'))) {
      return 'Loisirs';
    }
    
    if (objetLower.contains(RegExp(r'droit|défense|justice|citoyen'))) {
      return 'Défense des droits';
    }
    
    if (objetLower.contains(RegExp(r'religion|culte|spirituel|église'))) {
      return 'Religion';
    }
    
    return 'Autres';
  }
}
