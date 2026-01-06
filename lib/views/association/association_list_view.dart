import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/association.dart';
import '../../controllers/association_controller.dart';

/// Vue affichant la liste des associations avec recherche et filtres
class AssociationListView extends StatefulWidget {
  const AssociationListView({super.key});

  @override
  State<AssociationListView> createState() => _AssociationListViewState();
}

class _AssociationListViewState extends State<AssociationListView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedCategory;
  String? _initialQuery;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Récupérer les arguments de navigation
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _initialQuery = args['query'] as String?;
        _selectedCategory = args['category'] as String?;
        
        if (_initialQuery != null) {
          _searchController.text = _initialQuery!;
        }
      }
      _loadAssociations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Détecte le scroll pour charger plus de résultats
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final controller = context.read<AssociationController>();
      if (!controller.isLoading && controller.hasMoreResults) {
        controller.loadMoreResults();
      }
    }
  }

  /// Charge les associations depuis l'API
  Future<void> _loadAssociations() async {
    final controller = context.read<AssociationController>();
    await controller.searchAssociations(
      query: _searchController.text.trim(),
      categorie: _selectedCategory,
      resetPage: true,
    );
  }



  /// Gère la recherche d'associations
  void _handleSearch(String query) {
    _loadAssociations();
  }

  /// Affiche le dialogue de filtres
  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filtres',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Catégorie'),
                subtitle: Text(_selectedCategory ?? 'Toutes'),
                onTap: () {
                  // TODO: Implémenter la sélection de catégorie
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Localisation'),
                subtitle: const Text('Autour de vous'),
                onTap: () {
                  // TODO: Implémenter la sélection de localisation
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Note minimum'),
                subtitle: const Text('Toutes les notes'),
                onTap: () {
                  // TODO: Implémenter le filtre de note
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                        });
                        Navigator.pop(context);
                        _loadAssociations();
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadAssociations();
                      },
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Associations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Vue carte',
            onPressed: () {
              Navigator.pushNamed(context, '/map');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _handleSearch,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _handleSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filtres',
                  onPressed: _showFilters,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Chip de catégorie sélectionnée
          if (_selectedCategory != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(_selectedCategory!),
                  onDeleted: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                    _loadAssociations();
                  },
                ),
              ),
            ),

          // Liste des associations avec Provider
          Expanded(
            child: Consumer<AssociationController>(
              builder: (context, controller, _) {
                // Affichage du chargement
                if (controller.isLoading && controller.associations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Message d'erreur
                if (controller.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          controller.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAssociations,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                // Liste vide
                if (controller.associations.isEmpty) {
                  return _buildEmptyState();
                }

                // Affichage de la liste
                return Column(
                  children: [
                    // Nombre de résultats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '${controller.associations.length} association(s) trouvée(s)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                    // Liste avec scroll infini
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadAssociations,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.associations.length + 
                                    (controller.hasMoreResults ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Indicateur de chargement en bas
                            if (index == controller.associations.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final association = controller.associations[index];
                            return _buildAssociationCard(association);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte d'association
  Widget _buildAssociationCard(Association association) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/association-detail',
            arguments: {'id': association.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et catégorie
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          association.nom,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (association.categorie != null) ...[
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(
                              association.categorie!,
                              style: const TextStyle(fontSize: 12),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (association.noteGlobale != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            association.noteGlobale!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Description/Objet
              if (association.objet != null)
                Text(
                  association.objet!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              const SizedBox(height: 8),

              // Localisation
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      association.adresseComplete,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Nombre d'avis
              if (association.nombreAvis != null && association.nombreAvis! > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${association.nombreAvis} avis',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// État vide quand aucune association n'est trouvée
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune association trouvée',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier votre recherche ou vos filtres',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = null;
                });
                _loadAssociations();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser la recherche'),
            ),
          ],
        ),
      ),
    );
  }
}
