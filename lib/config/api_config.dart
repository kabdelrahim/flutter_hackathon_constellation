/// Configuration des endpoints de l'API RNA (Répertoire National des Associations)
/// et de l'API backend Constellation
class ApiConfig {
  // API RNA - Répertoire National des Associations via HuWise (Opendatasoft)
  // Documentation: https://hub.huwise.com/api/explore/v2.1/catalog/datasets/ref-france-association-repertoire-national/console
  static const String rnaBaseUrl = 'https://hub.huwise.com/api/explore/v2.1';
  static const String rnaDataset = 'ref-france-association-repertoire-national';

  // Endpoints RNA
  static const String rnaSearchEndpoint = '/catalog/datasets/$rnaDataset/records';
  static const String rnaExportsEndpoint = '/catalog/datasets/$rnaDataset/exports';
  static const String rnaFacetsEndpoint = '/catalog/datasets/$rnaDataset/facets';

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

/// Catégories désactivées faute de mapping fiable avec l'OpenData
class AssociationCategories {
  static const List<String> all = [];

  /// Détection désactivée tant que les catégories ne sont pas fiables
  static String? detectCategory(String? objet) {
    return null;
  }
}
