import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import '../services/backend_service.dart';
import '../services/auth_service.dart';

/// Contrôleur pour la gestion des commentaires
class CommentController extends ChangeNotifier {
  final BackendService _backendService;
  final AuthService _authService;

  CommentController(this._backendService, this._authService);

  Map<String, List<Comment>> _commentsByAssociation = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Récupère les commentaires d'une association
  List<Comment> getCommentsForAssociation(String associationId) {
    return _commentsByAssociation[associationId] ?? [];
  }

  /// Charge les commentaires d'une association depuis le backend
  Future<void> loadComments(String associationId) async {
    _setLoading(true);
    _clearError();

    try {
      final comments = await _backendService.getComments(associationId);
      _commentsByAssociation[associationId] = comments;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des commentaires: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Ajoute un nouveau commentaire
  Future<bool> addComment({
    required String associationId,
    required String contenu,
    int? note,
  }) async {
    if (_authService.currentUser == null) {
      _setError('Vous devez être connecté pour commenter');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final comment = await _backendService.addComment(
        associationId: associationId,
        contenu: contenu,
        note: note,
      );

      // Ajoute le commentaire à la liste locale
      final comments = _commentsByAssociation[associationId] ?? [];
      comments.insert(0, comment); // Ajoute au début
      _commentsByAssociation[associationId] = comments;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout du commentaire: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Modifie un commentaire existant
  /// TODO: Implémenter updateComment dans BackendService
  // Future<bool> updateComment({
  //   required String commentId,
  //   required String associationId,
  //   required String contenu,
  //   int? note,
  // }) async {
  //   _setLoading(true);
  //   _clearError();

  //   try {
  //     final updatedComment = await _backendService.updateComment(
  //       commentId: commentId,
  //       contenu: contenu,
  //       note: note,
  //     );

  //     // Met à jour le commentaire dans la liste locale
  //     final comments = _commentsByAssociation[associationId];
  //     if (comments != null) {
  //       final index = comments.indexWhere((c) => c.id == commentId);
  //       if (index != -1) {
  //         comments[index] = updatedComment;
  //         _commentsByAssociation[associationId] = comments;
  //       }
  //     }

  //     notifyListeners();
  //     return true;
  //   } catch (e) {
  //     _setError('Erreur lors de la modification: ${e.toString()}');
  //     return false;
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  /// Supprime un commentaire
  Future<bool> deleteComment({
    required String commentId,
    required String associationId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _backendService.deleteComment(commentId);

      // Supprime le commentaire de la liste locale
      final comments = _commentsByAssociation[associationId];
      if (comments != null) {
        comments.removeWhere((c) => c.id == commentId);
        _commentsByAssociation[associationId] = comments;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Vérifie si l'utilisateur connecté est l'auteur du commentaire
  bool canEditComment(Comment comment) {
    final currentUser = _authService.currentUser;
    return currentUser != null && currentUser.id == comment.userId;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Efface le message d'erreur actuel
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
