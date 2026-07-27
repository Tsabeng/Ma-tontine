import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/association_model.dart';
import '../services/association_service.dart';

const _kDerniereAssociationKey = 'derniere_association_id';

/// Gère la liste des associations de l'utilisateur, l'association
/// active, et le basculement entre associations. Référence : §2.2,
/// §3.2.3, §3.2.4 — le cœur de la fonctionnalité multi-associations.
class AssociationViewModel extends ChangeNotifier {
  final AssociationService _service;

  AssociationViewModel(this._service);

  List<AssociationModel> mesAssociations = [];
  AssociationModel? associationActive;
  bool isLoading = false;
  String? errorMessage;

  /// Charge toutes les associations de l'utilisateur et restaure la
  /// dernière association active sauvegardée localement (§3.1.2, §4.3.2).
  Future<void> chargerAssociations(List<String> associationIds) async {
    isLoading = true;
    notifyListeners();
    try {
      mesAssociations = await _service.listerAssociationsUtilisateur(associationIds);

      final prefs = await SharedPreferences.getInstance();
      final derniereId = prefs.getString(_kDerniereAssociationKey);
      if (derniereId != null) {
        final match = mesAssociations.where((a) => a.id == derniereId);
        if (match.isNotEmpty) associationActive = match.first;
      }
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  /// Basculement d'association — §2.2.2 et §3.2.4.
  Future<void> selectionnerAssociation(AssociationModel association) async {
    associationActive = association;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDerniereAssociationKey, association.id);
    notifyListeners();
  }

  Future<AssociationModel?> creerAssociation({
    required String uid,
    required String nom,
    String? description,
    String? pays,
    String? ville,
    String? email,
    String? telephone,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final association = await _service.creerAssociation(
        uid: uid,
        nom: nom,
        description: description,
        pays: pays,
        ville: ville,
        email: email,
        telephone: telephone,
      );
      mesAssociations = [...mesAssociations, association];
      await selectionnerAssociation(association);
      return association;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AssociationModel?> rejoindreParCode({required String uid, required String code}) async {
    isLoading = true;
    notifyListeners();
    try {
      final association = await _service.rejoindreParCode(uid: uid, code: code);
      mesAssociations = [...mesAssociations, association];
      await selectionnerAssociation(association);
      return association;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
