import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';

/// Gère les prêts de l'association active. Référence : §3.6.2.
class LoanViewModel extends ChangeNotifier {
  final LoanService _service;
  StreamSubscription<List<LoanModel>>? _sub;

  LoanViewModel(this._service);

  List<LoanModel> prets = [];
  bool isLoading = true;
  String? errorMessage;

  void ecouterPrets(String associationId) {
    _sub?.cancel();
    isLoading = true;
    notifyListeners();
    _sub = _service.watchPretsAssociation(associationId).listen(
      (data) {
        prets = data;
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

  Future<bool> demanderPret({
    required String associationId,
    required String membreId,
    required double montant,
    required double tauxInteret,
    required int dureeEnMois,
  }) async {
    try {
      await _service.demanderPret(
        associationId: associationId,
        membreId: membreId,
        montant: montant,
        tauxInteret: tauxInteret,
        dureeEnMois: dureeEnMois,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> enregistrerRemboursement(String loanId, double montant) =>
      _service.enregistrerRemboursement(loanId: loanId, montant: montant);

  Future<void> validerPret(String loanId) => _service.validerPret(loanId);

  Future<void> refuserPret(String loanId) => _service.refuserPret(loanId);

  /// Bilan des prêts d'un membre — alimente "Mon Bilan" (§3.6.3).
  List<LoanModel> pretsDeMembre(String membreId) =>
      prets.where((p) => p.membreId == membreId).toList();

  /// Demandes en attente de validation admin — §3.6.2.
  List<LoanModel> get pretsEnAttente =>
      prets.where((p) => p.statut == StatutPret.en_attente).toList();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
