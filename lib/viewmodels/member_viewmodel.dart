import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/member_model.dart';
import '../models/user_model.dart';
import '../services/member_service.dart';

/// Gère la liste des membres de l'association active, avec recherche
/// par nom, filtrage par rôle et tri par date d'adhésion — §3.3.2.
class MemberViewModel extends ChangeNotifier {
  final MemberService _service;
  StreamSubscription<List<MemberModel>>? _sub;

  MemberViewModel(this._service);

  List<MemberModel> _tousLesMembres = [];
  bool isLoading = true;
  String? errorMessage;

  String recherche = '';
  MembreRole? filtreRole;

  List<MemberModel> get membresFiltres {
    var liste = _tousLesMembres;
    if (recherche.isNotEmpty) {
      liste = liste.where((m) => (m.nomComplet ?? '').toLowerCase().contains(recherche.toLowerCase())).toList();
    }
    if (filtreRole != null) {
      liste = liste.where((m) => m.role == filtreRole).toList();
    }
    return liste;
  }

  void ecouterMembres(String associationId) {
    _sub?.cancel();
    isLoading = true;
    notifyListeners();
    _sub = _service.watchMembres(associationId).listen(
      (data) {
        _tousLesMembres = data;
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void mettreAJourRecherche(String texte) {
    recherche = texte;
    notifyListeners();
  }

  void appliquerFiltreRole(MembreRole? role) {
    filtreRole = role;
    notifyListeners();
  }

  Future<void> ajouterMembre({
    required String associationId,
    required String uid,
    String? nomComplet,
    String? email,
    String? telephone,
    String? adresse,
    MembreRole role = MembreRole.membre,
  }) {
    return _service.ajouterMembre(
      associationId: associationId,
      uid: uid,
      nomComplet: nomComplet,
      email: email,
      telephone: telephone,
      adresse: adresse,
      role: role,
    );
  }

  bool isCreatingMember = false;

  Future<bool> ajouterMembreParInformations({
    required String associationId,
    required String nomComplet,
    required String email,
    String? telephone,
    String? adresse,
    MembreRole role = MembreRole.membre,
  }) async {
    isCreatingMember = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.ajouterMembreParInformations(
        associationId: associationId,
        nomComplet: nomComplet,
        email: email,
        telephone: telephone,
        adresse: adresse,
        role: role,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isCreatingMember = false;
      notifyListeners();
    }
  }

  Future<void> supprimerMembre(String associationId, String uid) =>
      _service.supprimerMembre(associationId, uid);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}