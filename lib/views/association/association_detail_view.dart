import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/association.dart';
import '../../models/comment.dart';
import '../../controllers/association_controller.dart';
import '../../controllers/comment_controller.dart';
import '../../controllers/rating_controller.dart';
import '../../controllers/auth_controller.dart';

/// Vue détaillée d'une association avec toutes ses informations
class AssociationDetailView extends StatefulWidget {
  const AssociationDetailView({super.key});

  @override
  State<AssociationDetailView> createState() => _AssociationDetailViewState();
}

class _AssociationDetailViewState extends State<AssociationDetailView> {
  String? _associationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _associationId = args['id'] as String?;
        if (_associationId != null) {
          _loadAssociationDetails();
        }
      }
    });
  }

  /// Charge les détails de l'association
  Future<void> _loadAssociationDetails() async {
    if (_associationId == null) return;

    final associationController = context.read<AssociationController>();
    final commentController = context.read<CommentController>();
    final ratingController = context.read<RatingController>();

    // Chargement parallèle des données
    await Future.wait([
      associationController.getAssociationById(_associationId!),
      commentController.loadComments(_associationId!),
      ratingController.loadRatingStats(_associationId!),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      AssociationController,
      CommentController,
      RatingController
    >(
      builder:
          (
            context,
            associationController,
            commentController,
            ratingController,
            _,
          ) {
            final association = associationController.selectedAssociation;
            final isLoading =
                associationController.isLoading ||
                commentController.isLoading ||
                ratingController.isLoading;

            return Scaffold(
              appBar: AppBar(
                title: Text(association?.nom ?? 'Association'),
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
              body: isLoading && association == null
                  ? const Center(child: CircularProgressIndicator())
                  : association == null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _loadAssociationDetails,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(association),
                            _buildInfoSection(association),
                            _buildLocationMap(association),
                            _buildContactSection(association),
                            _buildRatingSection(association, ratingController),
                            _buildCommentsSection(
                              association,
                              commentController.getCommentsForAssociation(
                                _associationId!,
                              ),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
              floatingActionButton:
                  association != null && !association.estRevendiquee
                  ? FloatingActionButton.extended(
                      onPressed: () {
                        _handleClaim(context, association);
                      },
                      icon: const Icon(Icons.verified_user),
                      label: const Text('Revendiquer'),
                    )
                  : null,
            );
          },
    );
  }

  /// Gère la revendication d'une association
  void _handleClaim(BuildContext context, Association association) {
    final authController = context.read<AuthController>();

    if (!authController.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour revendiquer'),
        ),
      );
      return;
    }

    // TODO: Implémenter le dialogue de revendication
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fonctionnalité à venir')));
  }

  /// En-tête avec photo et informations principales
  Widget _buildHeader(Association association) {
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
                  association.nom,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (association.estRevendiquee)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
          if (association.categorie != null) ...[
            const SizedBox(height: 8),
            Text(
              association.categorie!,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  association.adresseComplete,
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
  Widget _buildInfoSection(Association association) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À propos',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            association.description ??
                association.objet ??
                'Pas de description disponible',
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  /// Section de contact
  Widget _buildContactSection(Association association) {
    if (association.email == null &&
        association.telephone == null &&
        association.siteWeb == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (association.telephone != null)
            _buildContactItem(
              icon: Icons.phone,
              label: 'Téléphone',
              value: association.telephone!,
              onTap: () {
                // TODO: Ouvrir l'application téléphone
              },
            ),
          if (association.email != null)
            _buildContactItem(
              icon: Icons.email,
              label: 'Email',
              value: association.email!,
              onTap: () {
                // TODO: Ouvrir l'application email
              },
            ),
          if (association.siteWeb != null)
            _buildContactItem(
              icon: Icons.language,
              label: 'Site web',
              value: association.siteWeb!,
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(value, style: const TextStyle(fontSize: 16)),
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
  Widget _buildRatingSection(
    Association association,
    RatingController ratingController,
  ) {
    final authController = context.read<AuthController>();
    final isAuthenticated = authController.isAuthenticated;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (association.noteGlobale != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  association.noteGlobale!.toStringAsFixed(1),
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
                      rating: association.noteGlobale!,
                      itemBuilder: (context, index) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${association.nombreAvis ?? 0} avis',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],
          const Text(
            'Votre avis',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (!isAuthenticated) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Connectez-vous pour noter et commenter',
                      style: TextStyle(color: Colors.blue[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 40,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) async {
                final success = await ratingController.rateAssociation(
                  associationId: _associationId!,
                  note: rating.toInt(),
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note enregistrée !')),
                  );
                  await _loadAssociationDetails();
                }
              },
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isAuthenticated
                ? _showAddCommentDialog
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Connectez-vous pour commenter'),
                        action: SnackBarAction(
                          label: 'Connexion',
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.comment),
            label: const Text('Laisser un commentaire'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Section des commentaires
  Widget _buildCommentsSection(
    Association association,
    List<Comment> comments,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Avis (${comments.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (comments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun avis pour le moment',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Soyez le premier à donner votre avis !',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...comments.map((comment) => _buildCommentCard(comment)),
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
                CircleAvatar(child: Text(comment.userName[0])),
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
                          itemBuilder: (context, index) =>
                              const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 16,
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(comment.dateCreation),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  void _showAddCommentDialog() {
    final commentController = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Votre commentaire'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Note', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Center(
                  child: RatingBar.builder(
                    initialRating: rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 36,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (r) {
                      setDialogState(() => rating = r);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Commentaire', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Partagez votre expérience...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (commentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le commentaire est requis')),
                  );
                  return;
                }

                final commentCtrl = context.read<CommentController>();
                final success = await commentCtrl.addComment(
                  associationId: _associationId!,
                  contenu: commentController.text.trim(),
                  note: rating.toInt(),
                );

                Navigator.of(ctx).pop();

                if (success) {
                  await _loadAssociationDetails();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Commentaire ajouté !')),
                    );
                  }
                }
              },
              child: const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMap(Association association) {
    if (association.latitude == null || association.longitude == null) {
      return const SizedBox.shrink();
    }

    final LatLng position = LatLng(association.latitude!, association.longitude!);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Localisation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 250,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: 15,
                  minZoom: 5,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.constellation.app',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: position,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.place, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  association.adresseComplete,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ],
          ),
        ],
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
