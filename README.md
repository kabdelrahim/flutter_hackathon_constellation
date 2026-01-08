# 🌟 Constellation - Annuaire des Associations

<div align="center">

**Plateforme hybride annuaire & réseau social pour découvrir et interagir avec les 1,5 million d'associations françaises**

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[Fonctionnalités](#-fonctionnalités) •
[Installation](#-installation) •
[Architecture](#-architecture) •
[Technologies](#-technologies) •
[Contribuer](#-contribuer)

</div>

---

## 📖 Description

**Constellation** est une application mobile cross-platform qui répond à une problématique nationale : bien que la France compte plus de 1,5 million d'associations, leurs informations sont souvent dispersées et peu accessibles.

### Objectifs
- 🔍 **Découvrir** les associations autour de soi grâce à la géolocalisation
- 📍 **Visualiser** les associations sur une carte interactive (OpenStreetMap)
- 💬 **Partager** son expérience via commentaires et notes
- 📊 **Enrichir** les données publiques avec des informations communautaires
- 🏛️ **Revendiquer** sa page pour les présidents d'associations

---

## ✨ Fonctionnalités

### Pour les Utilisateurs
- ✅ Recherche multicritères (nom, ville, code postal, département, région)
- ✅ Géolocalisation et recherche par proximité (rayon configurable)
- ✅ Carte interactive avec marqueurs des associations
- ✅ Fiches détaillées avec toutes les informations légales
- ✅ Système de notation (1-5 étoiles)
- ✅ Commentaires et avis communautaires
- ✅ Authentification sécurisée (inscription/connexion)

### Pour les Présidents d'Associations
- 🔒 Revendication de page d'association
- 📝 Enrichissement des informations (description, photos, contacts)
- 📢 Gestion des actualités
- 👥 Interaction avec les membres

### Données
- 📊 **1,5M+ associations** via l'API RNA (Répertoire National des Associations)
- 🔄 Données officielles en temps réel depuis HuWise/Opendatasoft
- 💾 Enrichissement communautaire via backend PostgreSQL

---

## 🚀 Installation

### Prérequis

Avant de commencer, assurez-vous d'avoir installé :

- **Flutter SDK** ≥ 3.9.2 ([Télécharger Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK** ≥ 3.9.2 (inclus avec Flutter)
- **Git** ([Télécharger Git](https://git-scm.com/downloads))
- Un éditeur de code (**VS Code** recommandé avec l'extension Flutter)
- Pour Android : **Android Studio** avec SDK Android
- Pour iOS : **Xcode** (macOS uniquement)

### Vérifier l'installation de Flutter

```bash
flutter doctor
```

Cette commande vérifie que tout est correctement configuré. Résolvez les problèmes signalés avant de continuer.

---

### 📥 Étapes d'Installation

#### 1. Cloner le Repository

```bash
git clone https://github.com/votre-username/flutter_hackathon_constellation.git
cd flutter_hackathon_constellation
```

#### 2. Installer les Dépendances

```bash
flutter pub get
```

Cette commande télécharge tous les packages nécessaires listés dans `pubspec.yaml`.

#### 3. Configuration de l'API Backend (Optionnel)

> ⚠️ **Note** : L'application fonctionne avec l'API RNA publique sans backend. Le backend est optionnel pour les fonctionnalités sociales (commentaires, notes, revendications).

Si vous souhaitez utiliser le backend complet :

1. Créer un fichier `.env` à la racine :
```bash
cp .env.example .env
```

2. Modifier `lib/config/api_config.dart` :
```dart
static const String backendBaseUrl = 'http://votre-backend-url.com/api';
```

3. Suivre les instructions dans [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) pour configurer PostgreSQL

#### 4. Vérifier les Permissions

##### Android (`android/app/src/main/AndroidManifest.xml`)
Les permissions suivantes sont déjà configurées :
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

##### iOS (`ios/Runner/Info.plist`)
Les permissions suivantes sont déjà configurées :
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Constellation utilise votre position pour trouver les associations près de vous</string>
```

#### 5. Lancer l'Application

##### Sur Émulateur/Simulateur

Démarrer un émulateur Android ou simulateur iOS, puis :

```bash
flutter run
```

##### Sur Appareil Physique

1. Activer le mode développeur sur votre appareil
2. Connecter via USB
3. Exécuter :
```bash
flutter devices  # Liste les appareils connectés
flutter run -d <device-id>
```

##### Version Web

```bash
flutter run -d chrome
```

##### Build de Production

```bash
# Android (APK)
flutter build apk --release

# Android (App Bundle)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

Les fichiers compilés se trouvent dans :
- Android : `build/app/outputs/`
- iOS : `build/ios/`
- Web : `build/web/`

---

## 🏗️ Architecture

### Structure du Projet

```
lib/
├── app/                      # Configuration de l'application
│   ├── app.dart              # Point d'entrée de l'app
│   ├── routes.dart           # Gestion des routes/navigation
│   └── theme.dart            # Thème et styles globaux
│
├── config/                   # Configuration
│   └── api_config.dart       # URLs API et paramètres
│
├── controllers/              # Contrôleurs (Logique métier)
│   ├── association_controller.dart  # Gestion des associations
│   ├── auth_controller.dart         # Authentification
│   ├── comment_controller.dart      # Commentaires
│   └── rating_controller.dart       # Notes/ratings
│
├── models/                   # Modèles de données
│   ├── association.dart      # Modèle Association
│   ├── user.dart            # Modèle Utilisateur
│   ├── comment.dart         # Modèle Commentaire
│   └── rating.dart          # Modèle Note
│
├── repositories/             # Couche d'accès aux données
│   └── association_repository.dart  # Fusion OpenData + Backend
│
├── services/                 # Services externes
│   ├── rna_api_service.dart      # API RNA (OpenData)
│   ├── backend_service.dart      # API Backend
│   └── auth_service.dart         # Service d'authentification
│
├── utils/                    # Utilitaires
│   └── ui_components.dart    # Composants UI réutilisables
│
├── views/                    # Interfaces utilisateur
│   ├── home/                 # Page d'accueil
│   │   └── home_view.dart
│   ├── association/          # Pages associations
│   │   ├── association_list_view.dart
│   │   └── association_detail_view.dart
│   └── auth/                 # Pages authentification
│       ├── login_view.dart
│       └── register_view.dart
│
└── main.dart                 # Point d'entrée Flutter
```

### Architecture MVC avec Provider

```
┌─────────────┐
│    View     │ ← Interface utilisateur (Widgets Flutter)
│  (Widget)   │
└──────┬──────┘
       │ écoute via Consumer/Provider.of
       │
┌──────▼──────┐
│ Controller  │ ← Logique métier + État (ChangeNotifier)
│ (Provider)  │
└──────┬──────┘
       │ appelle
       │
┌──────▼──────┐
│ Repository  │ ← Agrégation de données
└──────┬──────┘
       │ appelle
       │
┌──────▼──────┐
│  Services   │ ← Communication API
└─────────────┘
       │
       ▼
   [API RNA] [Backend]
```

#### Flux de Données

1. **View** : Affiche l'UI et écoute les changements via `Consumer<Controller>`
2. **Controller** : Gère l'état, orchestre la logique, notifie les changements
3. **Repository** : Combine plusieurs sources de données (RNA + Backend)
4. **Services** : Communication HTTP avec les APIs
5. **Models** : Représentation typée des données

---

## 🛠️ Technologies

### Frontend
- **Flutter 3.9.2** - Framework UI cross-platform
- **Dart 3.9.2** - Langage de programmation
- **Provider 6.1.1** - State management
- **flutter_map 6.1.0** - Cartes OpenStreetMap
- **geolocator 11.0.0** - Géolocalisation
- **http 1.2.0** - Client HTTP

### APIs & Données
- **API RNA HuWise** - Répertoire National des Associations (OpenData)
  - URL : `https://hub.huwise.com/api/explore/v2.1`
  - Dataset : `ref-france-association-repertoire-national`
  - Langage de requête : ODSQL
- **Backend PostgreSQL** - Données enrichies (optionnel)

### Packages Principaux
```yaml
dependencies:
  provider: ^6.1.1              # State management
  http: ^1.2.0                  # Requêtes HTTP
  flutter_map: ^6.1.0           # Cartes OpenStreetMap
  latlong2: ^0.9.0              # Coordonnées GPS
  geolocator: ^11.0.0           # Géolocalisation
  flutter_rating_bar: ^4.0.1    # Système de notation
  cached_network_image: ^3.3.1  # Cache d'images
  shared_preferences: ^2.2.2    # Stockage local
  email_validator: ^2.1.17      # Validation d'emails
```

---

## 📚 Documentation Technique

### Fichiers de Documentation
- [AGENTS.md](AGENTS.md) - Déclaration d'utilisation des outils IA
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Schéma de la base de données

### Concepts Clés

#### 1. Recherche Géographique

La recherche par proximité utilise le paramètre `geofilter.distance` de l'API RNA :

```dart
// Recherche dans un rayon de 15km
await controller.searchNearby(
  latitude: 48.8566,
  longitude: 2.3522,
  radiusKm: 15.0,
);
```

#### 2. Fusion des Données

Les données RNA (officielles) sont enrichies avec les données communautaires :

```dart
// Dans AssociationRepository
final rnaData = await rnaApiService.searchAssociations(...);
final enrichedData = await backendService.getAssociationEnriched(id);
final merged = _mergeAssociationData(rnaData, enrichedData);
```

#### 3. État Réactif avec Provider

```dart
// Écouter les changements dans la vue
Consumer<AssociationController>(
  builder: (context, controller, child) {
    if (controller.isLoading) return CircularProgressIndicator();
    return ListView(children: controller.associations.map(...));
  },
);
```

---

## 🧪 Tests

### Exécuter les Tests

```bash
# Tous les tests
flutter test

# Tests avec couverture
flutter test --coverage
```

---

## 🐛 Débogage

### Problèmes Courants

#### 1. Erreur de géolocalisation
**Solution** : Vérifier les permissions dans `AndroidManifest.xml` et `Info.plist`

#### 2. "No associations found nearby"
**Solution** : Augmenter le rayon de recherche dans `home_view.dart` (ligne 47)

---

## 🤝 Contribuer

### Standards de Code
- Suivre les conventions Dart/Flutter
- Commenter les fonctions importantes en français
- Utiliser les linters (`flutter analyze`)

---

## 📋 Roadmap

### Version 1.0 (Actuelle)
- [x] Recherche d'associations via API RNA
- [x] Géolocalisation et recherche par proximité
- [x] Carte interactive
- [x] Commentaires et notes

### Version 1.1 (À venir)
- [ ] Favoris
- [ ] Mode hors-ligne
- [ ] Filtres avancés

---

## 📄 Licence

Ce projet est sous licence **MIT**.

---

## 🙏 Remerciements

- **HuWise/Opendatasoft** pour l'API RNA
- **Communauté Flutter** pour les packages open-source
- **OpenStreetMap** pour les données cartographiques

---

<div align="center">

**Fait avec ❤️ en France**

⭐ Si ce projet vous plaît, n'hésitez pas à lui donner une étoile !

</div> 
