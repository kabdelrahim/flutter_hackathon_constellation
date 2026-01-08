import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/association.dart';
import '../../controllers/association_controller.dart';

/// Vue moderne affichant la liste des associations
class AssociationListView extends StatefulWidget {
  const AssociationListView({super.key});

  @override
  State<AssociationListView> createState() => _AssociationListViewState();
}

class _AssociationListViewState extends State<AssociationListView> {
  final _searchController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _departementController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String? _initialQuery;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _initialQuery = args['query'] as String?;
        if (_initialQuery != null && _initialQuery!.trim().isNotEmpty) {
          _searchController.text = _initialQuery!;
          _loadAssociations();
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _departementController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final controller = context.read<AssociationController>();
      if (!controller.isLoading && controller.hasMoreResults) {
        controller.loadMoreResults();
      }
    }
  }

  Future<void> _loadAssociations() async {
    final controller = context.read<AssociationController>();
    await controller.searchAssociations(
      query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      ville: _villeController.text.trim().isEmpty ? null : _villeController.text.trim(),
      codePostal: _codePostalController.text.trim().isEmpty ? null : _codePostalController.text.trim(),
      departement: _departementController.text.trim().isEmpty ? null : _departementController.text.trim(),
      resetPage: true,
    );
  }

  void _handleSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final hasAnyText = _searchController.text.trim().isNotEmpty ||
          _villeController.text.trim().isNotEmpty ||
          _codePostalController.text.trim().isNotEmpty ||
          _departementController.text.trim().isNotEmpty;
      
      if (hasAnyText) {
        _loadAssociations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: Consumer<AssociationController>(
              builder: (context, controller, _) {
                if (controller.isLoading && controller.associations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage != null) {
                  return _buildErrorState(controller.errorMessage!);
                }

                if (controller.associations.isEmpty) {
                  return controller.hasSearched
                      ? _buildEmptyState()
                      : _buildPreSearchState();
                }

                return _buildAssociationsList(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recherche croisée', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          // Champ nom/mot-clé
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              onSubmitted: (_) => _loadAssociations(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Nom ou mot-clé...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Champ ville
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _villeController,
              onChanged: _handleSearch,
              onSubmitted: (_) => _loadAssociations(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Ville...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.location_city_rounded, color: Colors.grey[400]),
                suffixIcon: _villeController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _villeController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Ligne code postal + département
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: _codePostalController,
                    onChanged: _handleSearch,
                    onSubmitted: (_) => _loadAssociations(),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Code postal...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.pin_drop_rounded, color: Colors.grey[400]),
                      suffixIcon: _codePostalController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _codePostalController.clear();
                                _handleSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: _departementController,
                    onChanged: _handleSearch,
                    onSubmitted: (_) => _loadAssociations(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Département...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.map_rounded, color: Colors.grey[400]),
                      suffixIcon: _departementController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _departementController.clear();
                                _handleSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssociationsList(AssociationController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.searchAssociations(
        query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        resetPage: true,
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: controller.associations.length + (controller.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.associations.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final association = controller.associations[index];
          return _buildAssociationCard(association);
        },
      ),
    );
  }

  Widget _buildAssociationCard(Association association) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/association-detail',
              arguments: {'id': association.id},
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_rounded, size: 26, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        association.nom,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (association.ville != null)
                        Text(
                          association.ville!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 16),
            const Text('Aucune association trouvee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Essayez une autre recherche', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _loadAssociations();
              },
              child: const Text('Reinitialiser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _loadAssociations,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreSearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search_rounded, size: 48, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 16),
            const Text('Commencez une recherche', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Saisissez un nom, une ville ou ouvrez les filtres', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
