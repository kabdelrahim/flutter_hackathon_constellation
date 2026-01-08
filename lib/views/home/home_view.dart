import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../controllers/association_controller.dart';
import '../../models/association.dart';

/// Home screen simple et moderne
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;
  LatLng? _currentPosition;
  bool _locating = false;
  List<Association> _nearbyAssociations = [];
  bool _fetchingNearby = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _fetchNearbyAssociations() async {
    // Attendre la géoloc
    if (_currentPosition == null || !mounted) return;
    setState(() => _fetchingNearby = true);
    try {
      final controller = context.read<AssociationController>();
      
      // Utiliser searchNearby au lieu de searchAssociations
      // avec un rayon de 15 km pour avoir assez de résultats
      await controller.searchNearby(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: 15.0,
      );

      if (!mounted) return;

      // Les résultats sont déjà triés par distance par l'API
      final sorted = controller.associations
          .where((a) => a.hasCoordinates)
          .toList();

      setState(() {
        _nearbyAssociations = sorted;
        _fetchingNearby = false;
      });
    } catch (e) {
      setState(() => _fetchingNearby = false);
    }
  }

  double _calculateDistance(LatLng pos1, Association assoc) {
    if (!assoc.hasCoordinates) return double.infinity;
    return Geolocator.distanceBetween(
          pos1.latitude,
          pos1.longitude,
          assoc.latitude!,
          assoc.longitude!,
        ) /
        1000;
  }

  Future<void> _initLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locating = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _locating = false;
      });
      _fetchNearbyAssociations();
    } catch (_) {
      setState(() => _locating = false);
    }
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    Navigator.pushNamed(
      context,
      '/associations',
      arguments: query.isNotEmpty ? {'query': query} : <String, dynamic>{},
    );
  }

  void _onNavigationItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        // Liste simple sans géolocalisation
        _navigateToAssociations({});
        break;
      case 2:
        Navigator.pushNamed(context, '/login');
        break;
    }
  }

  void _navigateToAssociations(Map<String, dynamic> args) {
    final lat = _currentPosition?.latitude;
    final lng = _currentPosition?.longitude;

    // Si withCoordinates est true, on ajoute latitude/longitude
    final finalArgs = {
      ...args,
      if (args['withCoordinates'] == true && lat != null && lng != null) ...{
        'latitude': lat,
        'longitude': lng,
      },
    };

    Navigator.pushNamed(context, '/associations', arguments: finalArgs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Constellation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Mon compte',
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSearchBar(),
                const SizedBox(height: 32),
                _buildQuickActions(),
                const SizedBox(height: 40),
                _buildNearbySection(),
                const SizedBox(height: 40),
                _buildInfoSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Decouvrez',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const Text(
          'les associations',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2563EB),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Explorez le plus grand annuaire français avec plus de 1,5 millions d\'associations',
          style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => _handleSearch(),
        decoration: InputDecoration(
          hintText: 'Rechercher une association...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: _handleSearch,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.explore_rounded,
        'label': 'Explorer',
        'args': <String, dynamic>{},
      },
      {
        'icon': Icons.location_on_rounded,
        'label': 'Pres de moi',
        'args': {
          'withCoordinates': true,
          // coords seront complétées dans _navigateToAssociations
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildActionButton(
                  action['icon'] as IconData,
                  action['label'] as String,
                  action['args'] as Map<String, dynamic>,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Map<String, dynamic> args,
  ) {
    return GestureDetector(
      onTap: () => _navigateToAssociations(args),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Autour de vous',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            TextButton(
              // "Voir tout" envoie avec géolocalisation
              onPressed: () =>
                  _navigateToAssociations({'withCoordinates': true}),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Voir tout', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildNearbyMapPreview(),
        const SizedBox(height: 12),
        if (_fetchingNearby)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_nearbyAssociations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Aucune association trouvée près de vous',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ..._nearbyAssociations.take(3).map((assoc) {
            final distance = _calculateDistance(_currentPosition!, assoc);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/association-detail',
                    arguments: {'association': assoc},
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          size: 22,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assoc.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${assoc.codePostal} ${assoc.ville}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildNearbyMapPreview() {
    final height = 180.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            if (_currentPosition != null)
              FlutterMap(
                options: MapOptions(
                  initialCenter: _currentPosition!,
                  initialZoom: 14,
                  minZoom: 5,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.constellation.app',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      if (_currentPosition != null)
                        Marker(
                          point: _currentPosition!,
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                      ..._nearbyAssociations
                          .where((a) => a.hasCoordinates)
                          .map(
                            (assoc) => Marker(
                              point: LatLng(assoc.latitude!, assoc.longitude!),
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.location_on,
                                size: 32,
                                color: Colors.red.withOpacity(0.8),
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              )
            else
              Center(
                child: _locating
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Localisation indisponible',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: _initLocation,
                            child: const Text('Activer'),
                          ),
                        ],
                      ),
              ),
            Positioned(
              right: 8,
              bottom: 8,
              child: FilledButton.icon(
                // Bouton "Voir autour" envoie avec géolocalisation
                onPressed: () =>
                    _navigateToAssociations({'withCoordinates': true}),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.near_me, size: 16),
                label: const Text(
                  'Voir autour',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comment ca marche',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _buildInfoStep(
          Icons.search_rounded,
          'Recherchez',
          'Trouvez par nom, ville ou mot-cle',
        ),
        const SizedBox(height: 12),
        _buildInfoStep(
          Icons.map_rounded,
          'Explorez',
          'Carte interactive et liste detaillee',
        ),
        const SizedBox(height: 12),
        _buildInfoStep(
          Icons.star_rounded,
          'Participez',
          'Notez et partagez votre avis',
        ),
      ],
    );
  }

  Widget _buildInfoStep(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Accueil', 0),
              _buildNavItem(Icons.list_alt_rounded, 'Liste', 1),
              _buildNavItem(Icons.person_rounded, 'Profil', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavigationItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
