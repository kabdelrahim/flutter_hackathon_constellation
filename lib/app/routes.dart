import 'package:flutter/material.dart';
import '../views/home/home_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/association/association_list_view.dart';
import '../views/association/association_detail_view.dart';
import '../views/association/association_map_view.dart';

/// Définition des routes de l'application
/// Chaque route pointe vers une vue spécifique
final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const HomeView(),
  '/login': (context) => const LoginView(),
  '/register': (context) => const RegisterView(),
  '/associations': (context) => const AssociationListView(),
  '/association-detail': (context) => const AssociationDetailView(),
  '/map': (context) => const AssociationMapView(),
};

/// Gère les routes dynamiques avec paramètres
/// Utilisé pour passer des arguments entre les vues
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  // Extraction des arguments
  final args = settings.arguments as Map<String, dynamic>?;
  
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(
        builder: (context) => const HomeView(),
        settings: settings,
      );
      
    case '/login':
      return MaterialPageRoute(
        builder: (context) => const LoginView(),
        settings: settings,
      );
      
    case '/register':
      return MaterialPageRoute(
        builder: (context) => const RegisterView(),
        settings: settings,
      );
      
    case '/associations':
      return MaterialPageRoute(
        builder: (context) => const AssociationListView(),
        settings: settings,
      );
      
    case '/association-detail':
      if (args != null && args.containsKey('id')) {
        return MaterialPageRoute(
          builder: (context) => const AssociationDetailView(),
          settings: settings,
        );
      }
      // Redirection si pas d'ID
      return MaterialPageRoute(
        builder: (context) => const HomeView(),
      );
      
    case '/map':
      return MaterialPageRoute(
        builder: (context) => const AssociationMapView(),
        settings: settings,
      );
      
    default:
      // Route non trouvée - Redirection vers l'accueil
      return MaterialPageRoute(
        builder: (context) => const HomeView(),
      );
  }
}
