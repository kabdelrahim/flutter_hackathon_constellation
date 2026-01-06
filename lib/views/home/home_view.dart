import 'package:flutter/material.dart';

/// Home screen simple et moderne
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

  void _handleSearch() {
    final query = _searchController.text.trim();
    Navigator.pushNamed(
      context,
      '/associations',
      arguments: query.isNotEmpty ? {'query': query} : <String, dynamic>{},
    );
  }

  void _navigateToAssociations(Map<String, dynamic> args) {
    Navigator.pushNamed(context, '/associations', arguments: args);
  }

  void _onNavigationItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        _navigateToAssociations({});
        break;
      case 2:
        Navigator.pushNamed(context, '/map');
        break;
      case 3:
        Navigator.pushNamed(context, '/login');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Constellation', style: TextStyle(fontWeight: FontWeight.w700)),
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
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1),
        ),
        const Text(
          'les associations',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF2563EB), height: 1.1),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.explore_rounded, 'label': 'Explorer', 'args': <String, dynamic>{}},
      {'icon': Icons.location_on_rounded, 'label': 'Pres de moi', 'args': {'withCoordinates': true}},
      {'icon': Icons.map_rounded, 'label': 'Carte', 'args': {'_map': true}},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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

  Widget _buildActionButton(IconData icon, String label, Map<String, dynamic> args) {
    return GestureDetector(
      onTap: () {
        if (args.containsKey('_map')) {
          Navigator.pushNamed(context, '/map');
        } else {
          _navigateToAssociations(args);
        }
      },
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
    final nearby = [
      {'name': 'MJC Lyon Centre', 'city': 'Lyon (69)', 'distance': '1,2 km'},
      {'name': 'Sport & Solidarite', 'city': 'Villeurbanne (69)', 'distance': '2,8 km'},
      {'name': 'Culture Pour Tous', 'city': 'Lyon 3eme (69)', 'distance': '3,5 km'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Autour de vous', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () => _navigateToAssociations({'withCoordinates': true}),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Voir tout', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...nearby.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
                  child: const Icon(Icons.business_rounded, size: 22, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(item['city']!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Text(item['distance']!, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comment ca marche', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildInfoStep(Icons.search_rounded, 'Recherchez', 'Trouvez par nom, ville ou mot-cle'),
        const SizedBox(height: 12),
        _buildInfoStep(Icons.map_rounded, 'Explorez', 'Carte interactive et liste detaillee'),
        const SizedBox(height: 12),
        _buildInfoStep(Icons.star_rounded, 'Participez', 'Notez et partagez votre avis'),
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
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
              _buildNavItem(Icons.map_rounded, 'Carte', 2),
              _buildNavItem(Icons.person_rounded, 'Profil', 3),
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
          Icon(icon, color: isSelected ? const Color(0xFF2563EB) : Colors.grey[400], size: 24),
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
