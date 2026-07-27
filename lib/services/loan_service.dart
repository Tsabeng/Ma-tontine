import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loan_model.dart';
import 'firestore_service.dart';

/// Gère les prêts : demande, validation admin, remboursements,
/// pénalités de retard. Référence : §3.6.2.
class LoanService {
  /// Demande de prêt par un membre.
  Future<LoanModel> demanderPret({
    required String associationId,
    required String membreId,
    required double montant,
    required double tauxInteret,
    required int dureeEnMois,
  }) async {
    final docRef = FirestoreService.loans.doc();
    final dateDebut = DateTime.now();
    final dateFin = DateTime(dateDebut.year, dateDebut.month + dureeEnMois, dateDebut.day);
    final prochaineEcheance = DateTime(dateDebut.year, dateDebut.month + 1, dateDebut.day);

    final loan = LoanModel(
      id: docRef.id,
      associationId: associationId,
      membreId: membreId,
      montant: montant,
      tauxInteret: tauxInteret,
      duree: dureeEnMois,
      dateDebut: dateDebut,
      dateFin: dateFin,
      prochaineEcheance: prochaineEcheance,
      statut: StatutPret.en_attente,
      createdAt: dateDebut,
    );

    await docRef.set(loan.toMap());
    // TODO(notification_service): notifier l'administrateur pour validation.
    return loan;
  }

  Stream<List<LoanModel>> watchPretsAssociation(String associationId) {
    return FirestoreService.scopedTo(FirestoreService.loans, associationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LoanModel.fromFirestore).toList());
  }

  Stream<List<LoanModel>> watchPretsMembre(String associationId, String membreId) {
    return FirestoreService.scopedTo(FirestoreService.loans, associationId)
        .where('membreId', isEqualTo: membreId)
        .snapshots()
        .map((snap) => snap.docs.map(LoanModel.fromFirestore).toList());
  }

  /// Enregistre un remboursement partiel ou total et met à jour le statut.
  Future<void> enregistrerRemboursement({
    required String loanId,
    required double montant,
  }) async {
    final ref = FirestoreService.loans.doc(loanId);
    await FirestoreService.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final loan = LoanModel.fromFirestore(snap);
      final nouveauMontantRembourse = loan.montantRembourse + montant;
      final solde = loan.montantTotalDu + loan.penalites - nouveauMontantRembourse;

      tx.update(ref, {
        'montantRembourse': nouveauMontantRembourse,
        'statut': solde <= 0 ? 'solde' : 'en_cours',
      });
    });
  }

  /// Applique une pénalité de retard sur un prêt (à déclencher par une
  /// Cloud Function planifiée en production).
  Future<void> appliquerPenalite(String loanId, double montantPenalite) async {
    await FirestoreService.loans.doc(loanId).update({
      'penalites': FieldValue.increment(montantPenalite),
      'statut': 'impaye',
    });
  }

  /// Validation d'une demande de prêt par l'administrateur — §3.6.2.
  Future<void> validerPret(String loanId) async {
    await FirestoreService.loans.doc(loanId).update({'statut': 'en_cours'});
    // TODO(notification_service): notifier le membre que son prêt est validé.
  }

  /// Refus d'une demande de prêt par l'administrateur — §3.6.2.
  Future<void> refuserPret(String loanId) async {
    await FirestoreService.loans.doc(loanId).update({'statut': 'refuse'});
    // TODO(notification_service): notifier le membre que son prêt est refusé.
  }
}
