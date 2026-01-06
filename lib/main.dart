import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'controllers/auth_controller.dart';
import 'controllers/association_controller.dart';
import 'controllers/comment_controller.dart';
import 'controllers/rating_controller.dart';
import 'services/auth_service.dart';
import 'services/rna_api_service.dart';
import 'services/backend_service.dart';
import 'repositories/association_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation des dépendances
  final prefs = await SharedPreferences.getInstance();
  final httpClient = http.Client();
  
  // Services
  final authService = AuthService(
    client: httpClient,
    prefs: prefs,
  );
  final rnaApiService = RnaApiService(client: httpClient);
  final backendService = BackendService(
    client: httpClient,
    authService: authService,
  );
  
  // Repository
  final associationRepository = AssociationRepository(
    rnaApiService: rnaApiService,
    backendService: backendService,
  );

  runApp(
    MultiProvider(
      providers: [
        // Contrôleurs
        ChangeNotifierProvider(
          create: (_) => AuthController(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => AssociationController(associationRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CommentController(backendService, authService),
        ),
        ChangeNotifierProvider(
          create: (_) => RatingController(backendService, authService),
        ),
      ],
      child: const ConstellationApp(),
    ),
  );
}
