import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/caisse_model.dart';
import '../models/transaction_model.dart';
import 'firestore_service.dart';

/// Gère les caisses et leurs opérations financières. Référence : §3.5.
class CaisseService {
  /// Création d'une caisse — §3.5.2.
  Future<CaisseModel> creerCaisse({
    required String associationId,
    required String nom,
    required TypeCaisse type,
    String? description,
    double? objectif,
    double soldeInitial = 0,
    required String createdBy,
  }) async {
    final docRef = FirestoreService.caisses.doc();
    final caisse = CaisseModel(
      id: docRef.id,
      associationId: associationId,
      nom: nom,
      type: type,
      description: description,
      objectif: objectif,
      solde: soldeInitial,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
    await docRef.set(caisse.toMap());
    return caisse;
  }

  Stream<List<CaisseModel>> watchCaisses(String associationId) {
    return FirestoreService.scopedTo(FirestoreService.caisses, associationId)
        .snapshots()
        .map((snap) => snap.docs.map(CaisseModel.fromFirestore).toList());
  }

  Stream<CaisseModel> watchCaisse(String caisseId) {
    return FirestoreService.caisses.doc(caisseId).snapshots().map(CaisseModel.fromFirestore);
  }

  /// Historique des transactions d'une caisse, triées du plus récent au
  /// plus ancien — §3.5.3.
  Stream<List<TransactionModel>> watchTransactions(String caisseId) {
    return FirestoreService.transactions
        .where('caisseId', isEqualTo: caisseId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TransactionModel.fromFirestore).toList());
  }

  /// Ajoute une cotisation : crédite la caisse et journalise la
  /// transaction dans une transaction Firestore atomique (§3.5.3).
  Future<void> ajouterCotisation({
    required String associationId,
    required String caisseId,
    required String membreId,
    required double montant,
    String? description,
  }) {
    return _mouvementer(
      associationId: associationId,
      caisseId: caisseId,
      membreId: membreId,
      montant: montant,
      type: TypeTransaction.cotisation,
      description: description,
    );
  }

  /// Effectue un décaissement : débite la caisse (§3.5.3).
  Future<void> effectuerDecaissement({
    required String associationId,
    required String caisseId,
    required String membreId,
    required double montant,
    String? description,
  }) {
    return _mouvementer(
      associationId: associationId,
      caisseId: caisseId,
      membreId: membreId,
      montant: montant,
      type: TypeTransaction.decaissement,
      description: description,
    );
  }

  Future<void> _mouvementer({
    required String associationId,
    required String caisseId,
    required String membreId,
    required double montant,
    required TypeTransaction type,
    String? description,
  }) async {
    final caisseRef = FirestoreService.caisses.doc(caisseId);
    final transactionRef = FirestoreService.transactions.doc();

    await FirestoreService.instance.runTransaction((tx) async {
      final caisseSnap = await tx.get(caisseRef);
      final soldeActuel = (caisseSnap.data()?['solde'] as num?)?.toDouble() ?? 0;
      final estEntree = type == TypeTransaction.cotisation ||
          type == TypeTransaction.depot ||
          type == TypeTransaction.remboursement;

      final nouveauSolde = estEntree ? soldeActuel + montant : soldeActuel - montant;

      tx.update(caisseRef, {
        'solde': nouveauSolde,
        'contributeurs': FieldValue.arrayUnion([membreId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(transactionRef, TransactionModel(
        id: transactionRef.id,
        associationId: associationId,
        caisseId: caisseId,
        membreId: membreId,
        type: type,
        montant: montant,
        description: description,
        date: DateTime.now(),
        reference: transactionRef.id.substring(0, 8).toUpperCase(),
        createdAt: DateTime.now(),
      ).toMap());
    });
  }
}
