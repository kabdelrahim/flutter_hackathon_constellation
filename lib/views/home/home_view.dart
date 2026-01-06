import 'package:flutter/material.dart';

/// Vue d'accueil principale de l'application Constellation
/// Permet la recherche d'associations et la navigation vers les autres fonctionnalités
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Navigue vers les résultats de recherche
  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/associations',
        arguments: {'query': query},
      );
    }
  }

  /// Gère le changement d'onglet dans la navigation
  void _onNavigationItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigation vers différentes sections selon l'index
    switch (index) {
      case 0:
        // Déjà sur l'accueil
        break;
      case 1:
        // Voir toutes les associations (mode liste)
        Navigator.pushNamed(context, '/associations');
        break;
      case 2:
        // Voir les associations sur une carte
        Navigator.pushNamed(context, '/map');
        break;
      case 3:
        // Profil utilisateur
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Constellation'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Mon compte',
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête avec titre et description
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_city,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Découvrez les associations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Plus de 1,5 million d\'associations en France',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Barre de recherche principale
                  TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _handleSearch(),
                    decoration: InputDecoration(
                      hintText: 'Nom, catégorie, ville...',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          // TODO: Ouvrir le panneau de filtres
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Filtres à venir')),
                          );
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bouton de recherche
                  FilledButton.icon(
                    onPressed: _handleSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('Rechercher'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Section des catégories populaires
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catégories populaires',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(),
                ],
              ),
            ),

            // Section des associations à proximité
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Autour de vous',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/associations');
                        },
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNearbyAssociationsPlaceholder(),
                ],
              ),
            ),

            // Section comment ça marche
            Container(
              margin: const EdgeInsets.all(24.0),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comment ça marche ?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildHowItWorksStep(
                    icon: Icons.search,
                    title: 'Recherchez',
                    description: 'Trouvez des associations près de chez vous',
                  ),
                  _buildHowItWorksStep(
                    icon: Icons.info_outline,
                    title: 'Découvrez',
                    description: 'Consultez les informations et avis',
                  ),
                  _buildHowItWorksStep(
                    icon: Icons.star_outline,
                    title: 'Participez',
                    description: 'Partagez votre expérience',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigationItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Liste',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  /// Construit la grille de catégories
  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'Sport', 'icon': Icons.sports_soccer, 'color': Colors.orange},
      {'name': 'Culture', 'icon': Icons.palette, 'color': Colors.purple},
      {'name': 'Social', 'icon': Icons.group, 'color': Colors.blue},
      {'name': 'Environnement', 'icon': Icons.eco, 'color': Colors.green},
      {'name': 'Éducation', 'icon': Icons.school, 'color': Colors.indigo},
      {'name': 'Santé', 'icon': Icons.favorite, 'color': Colors.red},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/associations',
              arguments: {'category': category['name']},
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: (category['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (category['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category['icon'] as IconData,
                  size: 32,
                  color: category['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: category['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Placeholder pour les associations à proximité
  Widget _buildNearbyAssociationsPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Associations à proximité',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              'Activez la localisation',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une étape de "Comment ça marche"
  Widget _buildHowItWorksStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
