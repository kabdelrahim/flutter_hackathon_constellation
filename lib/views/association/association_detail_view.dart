import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/association.dart';
import '../../models/comment.dart';

/// Vue détaillée d'une association avec toutes ses informations
class AssociationDetailView extends StatefulWidget {
  const AssociationDetailView({super.key});

  @override
  State<AssociationDetailView> createState() => _AssociationDetailViewState();
}

class _AssociationDetailViewState extends State<AssociationDetailView> {
  bool _isLoading = false;
  Association? _association;
  List<Comment> _comments = [];
  String? _associationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _associationId = args['id'] as String?;
        _loadAssociationDetails();
      }
    });
  }

  /// Charge les détails de l'association
  Future<void> _loadAssociationDetails() async {
    if (_associationId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implémenter le chargement avec le contrôleur
      // final controller = context.read<AssociationController>();
      // final association = await controller.getAssociation(_associationId!);
      // final comments = await controller.getComments(_associationId!);
      
      // Simulation temporaire
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _association = _getMockAssociation();
          _comments = _getMockComments();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Données factices pour la démonstration
  Association _getMockAssociation() {
    return Association(
      id: _associationId ?? '1',
      nom: 'Association Sportive Locale',
      categorie: 'Sport',
      ville: 'Paris',
      codePostal: '75001',
      adresse: '12 Rue du Sport',
      objet: 'Promotion du sport pour tous les âges et tous les niveaux',
      description: 'Notre association propose des activités sportives variées dans une ambiance conviviale. Nous accueillons tous les publics, du débutant au confirmé.',
      noteGlobale: 4.5,
      nombreAvis: 23,
      latitude: 48.8566,
      longitude: 2.3522,
      email: 'contact@aslocale.fr',
      telephone: '01 23 45 67 89',
      siteWeb: 'https://www.aslocale.fr',
      estRevendiquee: true,
    );
  }

  List<Comment> _getMockComments() {
    return [
      Comment(
        id: '1',
        associationId: _associationId ?? '1',
        userId: 'user1',
        userName: 'Marie Dupont',
        contenu: 'Excellente association ! L\'équipe est très accueillante et les activités sont de qualité.',
        dateCreation: DateTime.now().subtract(const Duration(days: 5)),
        note: 5,
      ),
      Comment(
        id: '2',
        associationId: _associationId ?? '1',
        userId: 'user2',
        userName: 'Jean Martin',
        contenu: 'Très bonne expérience, je recommande vivement !',
        dateCreation: DateTime.now().subtract(const Duration(days: 12)),
        note: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_association?.nom ?? 'Association'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
            onPressed: () {
              // TODO: Implémenter le partage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partage à venir')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favoris',
            onPressed: () {
              // TODO: Implémenter les favoris
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favoris à venir')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _association == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadAssociationDetails,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        _buildInfoSection(),
                        _buildContactSection(),
                        _buildRatingSection(),
                        _buildCommentsSection(),
                        const SizedBox(height: 80), // Espace pour le bouton flottant
                      ],
                    ),
                  ),
                ),
      floatingActionButton: _association != null && !_association!.estRevendiquee
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Implémenter la revendication
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Revendication à venir')),
                );
              },
              icon: const Icon(Icons.verified_user),
              label: const Text('Revendiquer'),
            )
          : null,
    );
  }

  /// En-tête avec photo et informations principales
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _association!.nom,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_association!.estRevendiquee)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Vérifié',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_association!.categorie != null) ...[
            const SizedBox(height: 8),
            Text(
              _association!.categorie!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _association!.adresseComplete,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section d'informations
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À propos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _association!.description ?? _association!.objet ?? 'Pas de description disponible',
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Section de contact
  Widget _buildContactSection() {
    if (_association!.email == null &&
        _association!.telephone == null &&
        _association!.siteWeb == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (_association!.telephone != null)
            _buildContactItem(
              icon: Icons.phone,
              label: 'Téléphone',
              value: _association!.telephone!,
              onTap: () {
                // TODO: Ouvrir l'application téléphone
              },
            ),
          if (_association!.email != null)
            _buildContactItem(
              icon: Icons.email,
              label: 'Email',
              value: _association!.email!,
              onTap: () {
                // TODO: Ouvrir l'application email
              },
            ),
          if (_association!.siteWeb != null)
            _buildContactItem(
              icon: Icons.language,
              label: 'Site web',
              value: _association!.siteWeb!,
              onTap: () {
                // TODO: Ouvrir le navigateur
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  /// Section de notation
  Widget _buildRatingSection() {
    if (_association!.noteGlobale == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _association!.noteGlobale!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingBarIndicator(
                    rating: _association!.noteGlobale!,
                    itemBuilder: (context, index) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_association!.nombreAvis} avis',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              // TODO: Ouvrir le formulaire d'ajout d'avis
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ajout d\'avis à venir')),
              );
            },
            icon: const Icon(Icons.rate_review),
            label: const Text('Laisser un avis'),
          ),
        ],
      ),
    );
  }

  /// Section des commentaires
  Widget _buildCommentsSection() {
    if (_comments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avis récents',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ..._comments.map((comment) => _buildCommentCard(comment)),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(comment.userName[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (comment.note != null)
                        RatingBarIndicator(
                          rating: comment.note!.toDouble(),
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 16,
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(comment.dateCreation),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(comment.contenu),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Association introuvable'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      return 'Il y a ${(difference.inDays / 7).floor()} semaines';
    } else {
      return 'Il y a ${(difference.inDays / 30).floor()} mois';
    }
  }
}
