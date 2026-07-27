import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/caisse_model.dart';
import '../models/transaction_model.dart';
import '../services/caisse_service.dart';

/// Gère les caisses de l'association active et leurs transactions.
/// Référence : §3.5 (Caisses) et §3.6.3 (Bilan Membre).
class CaisseViewModel extends ChangeNotifier {
  final CaisseService _service;
  StreamSubscription<List<CaisseModel>>? _caissesSub;

  CaisseViewModel(this._service);

  List<CaisseModel> caisses = [];
  bool isLoading = true;
  String? errorMessage;

  double get soldeTotal => caisses.fold(0, (sum, c) => sum + c.solde);

  void ecouterCaisses(String associationId) {
    _caissesSub?.cancel();
    isLoading = true;
    notifyListeners();
    _caissesSub = _service.watchCaisses(associationId).listen(
      (data) {
        caisses = data;
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

  Future<bool> creerCaisse({
    required String associationId,
    required String nom,
    required TypeCaisse type,
    String? description,
    double? objectif,
    double soldeInitial = 0,
    required String createdBy,
  }) async {
    try {
      await _service.creerCaisse(
        associationId: associationId,
        nom: nom,
        type: type,
        description: description,
        objectif: objectif,
        soldeInitial: soldeInitial,
        createdBy: createdBy,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Stream<List<TransactionModel>> transactionsDe(String caisseId) =>
      _service.watchTransactions(caisseId);

  Future<bool> ajouterCotisation({
    required String associationId,
    required String caisseId,
    required String membreId,
    required double montant,
    String? description,
  }) async {
    try {
      await _service.ajouterCotisation(
        associationId: associationId,
        caisseId: caisseId,
        membreId: membreId,
        montant: montant,
        description: description,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> effectuerDecaissement({
    required String associationId,
    required String caisseId,
    required String membreId,
    required double montant,
    String? description,
  }) async {
    try {
      await _service.effectuerDecaissement(
        associationId: associationId,
        caisseId: caisseId,
        membreId: membreId,
        montant: montant,
        description: description,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _caissesSub?.cancel();
    super.dispose();
  }
}
