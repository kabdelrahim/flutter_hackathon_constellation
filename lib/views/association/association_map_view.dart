import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/association.dart';
import '../../controllers/association_controller.dart';

/// Vue cartographique affichant les associations sur une carte OpenStreetMap
/// Permet de filtrer les associations par catégorie et autres critères
class AssociationMapView extends StatefulWidget {
  const AssociationMapView({super.key});

  @override
  State<AssociationMapView> createState() => _AssociationMapViewState();
}

class _AssociationMapViewState extends State<AssociationMapView> {
  final MapController _mapController = MapController();
  
  // Position initiale (centre de la France)
  LatLng _currentPosition = const LatLng(46.603354, 1.888334);
  double _currentZoom = 6.0;
  
  // Filtres
  String? _selectedCategory;
  double _minRating = 0.0;
  double _maxDistance = 50.0; // km
  bool _onlyClaimedAssociations = false;
  bool _isLocationEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  /// Initialise la carte et charge les associations
  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadAssociations();
  }

  /// Récupère la position GPS actuelle de l'utilisateur
  Future<void> _getCurrentLocation() async {
    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Récupérer la position
      Position position = await Geolocator.getCurrentPosition();
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentZoom = 12.0;
          _isLocationEnabled = true;
        });
        
        _mapController.move(_currentPosition, _currentZoom);
      }
    } catch (e) {
      debugPrint('Erreur de géolocalisation: $e');
    }
  }

  /// Charge les associations depuis l'API
  Future<void> _loadAssociations() async {
    try {
      final controller = context.read<AssociationController>();
      await controller.searchAssociations(
        query: null,
        resetPage: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Applique les filtres sur les associations
  List<Association> _getFilteredAssociations(List<Association> associations) {
    return associations.where((association) {
      // Filtre par catégorie
      if (_selectedCategory != null && 
          association.categorie != _selectedCategory) {
        return false;
      }

      // Filtre par note minimum
      if (association.noteGlobale != null && 
          association.noteGlobale! < _minRating) {
        return false;
      }

      // Filtre par associations revendiquées
      if (_onlyClaimedAssociations && !association.estRevendiquee) {
        return false;
      }

      // Filtre par distance (si localisation activée)
      if (_isLocationEnabled && association.hasCoordinates) {
        final distance = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          association.latitude!,
          association.longitude!,
        ) / 1000; // Conversion en km
        
        if (distance > _maxDistance) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Affiche le panneau de filtres
  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtres',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Filtre par catégorie
                Text(
                  'Catégorie',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Toutes'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        setModalState(() {
                          _selectedCategory = null;
                        });
                      },
                    ),
                    ...['Sport', 'Culture', 'Social', 'Environnement', 'Éducation', 'Santé']
                        .map((category) => FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedCategory = selected ? category : null;
                                });
                              },
                            )),
                  ],
                ),
                const SizedBox(height: 24),

                // Filtre par note
                Text(
                  'Note minimum: ${_minRating.toStringAsFixed(1)} ⭐',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setModalState(() {
                      _minRating = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Filtre par distance
                if (_isLocationEnabled) ...[
                  Text(
                    'Distance maximum: ${_maxDistance.toInt()} km',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 200,
                    divisions: 199,
                    label: '${_maxDistance.toInt()} km',
                    onChanged: (value) {
                      setModalState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Filtre associations vérifiées
                SwitchListTile(
                  title: const Text('Uniquement les associations vérifiées'),
                  subtitle: const Text('Associations revendiquées par leurs présidents'),
                  value: _onlyClaimedAssociations,
                  onChanged: (value) {
                    setModalState(() {
                      _onlyClaimedAssociations = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategory = null;
                            _minRating = 0.0;
                            _maxDistance = 50.0;
                            _onlyClaimedAssociations = false;
                          });
                        },
                        child: const Text('Réinitialiser'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            // Les filtres sont appliqu\u00e9s automatiquement via Consumer
                          });
                          Navigator.pop(context);
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
      ),
    );
  }

  /// Retourne la couleur du marqueur selon la catégorie
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Sport':
        return Colors.orange;
      case 'Culture':
        return Colors.purple;
      case 'Social':
        return Colors.blue;
      case 'Environnement':
        return Colors.green;
      case 'Éducation':
        return Colors.indigo;
      case 'Santé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Affiche les détails d'une association dans un bottom sheet
  void _showAssociationDetails(Association association) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    association.nom,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (association.estRevendiquee)
                  const Icon(Icons.verified, color: Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            if (association.categorie != null)
              Chip(
                label: Text(association.categorie!),
                backgroundColor: _getCategoryColor(association.categorie).withOpacity(0.2),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(association.adresseComplete)),
              ],
            ),
            const SizedBox(height: 8),
            if (association.noteGlobale != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${association.noteGlobale!.toStringAsFixed(1)} (${association.nombreAvis} avis)',
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (association.objet != null)
              Text(
                association.objet!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/association-detail',
                    arguments: {'id': association.id},
                  );
                },
                child: const Text('Voir les détails'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssociationController>(
      builder: (context, controller, child) {
        final filteredAssociations = _getFilteredAssociations(controller.associations);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Carte des associations'),
            actions: [
              IconButton(
                icon: const Icon(Icons.list),
                tooltip: 'Vue liste',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/associations');
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtres',
                onPressed: _showFilterPanel,
              ),
            ],
          ),
          body: Stack(
            children: [
              // Carte OpenStreetMap
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition,
                  initialZoom: _currentZoom,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  // Tuiles OpenStreetMap
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.constellation.app',
                    maxZoom: 19,
                  ),
                  
                  // Marqueurs des associations
                  MarkerLayer(
                    markers: filteredAssociations
                        .where((association) => association.hasCoordinates)
                        .map((association) => Marker(
                              point: LatLng(
                                association.latitude!,
                                association.longitude!,
                              ),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showAssociationDetails(association),
                                child: Stack(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 40,
                                      color: _getCategoryColor(association.categorie),
                                    ),
                                    if (association.estRevendiquee)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.verified,
                                            size: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  
                  // Marqueur de position actuelle
                  if (_isLocationEnabled)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Indicateur de chargement
              if (controller.isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Barre d'information sur les filtres actifs
              if (_selectedCategory != null || 
                  _minRating > 0 || 
                  _onlyClaimedAssociations)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${filteredAssociations.length} association(s) affichée(s)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                                _minRating = 0.0;
                                _onlyClaimedAssociations = false;
                              });
                            },
                            child: const Text('Réinitialiser'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Bouton pour centrer sur la position actuelle
              if (_isLocationEnabled)
                FloatingActionButton(
                  heroTag: 'center',
                  onPressed: () {
                    _mapController.move(_currentPosition, 12.0);
                  },
                  child: const Icon(Icons.my_location),
                ),
              const SizedBox(height: 8),
              
              // Bouton pour recharger les associations
              FloatingActionButton(
                heroTag: 'refresh',
                onPressed: _loadAssociations,
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        );
      },
    );
  }
}
