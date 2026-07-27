import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeTransaction { cotisation, decaissement, depot, retrait, remboursement }

TypeTransaction typeTransactionFromString(String value) {
  return TypeTransaction.values.firstWhere(
    (t) => t.name == value,
    orElse: () => TypeTransaction.cotisation,
  );
}

extension TypeTransactionLabel on TypeTransaction {
  bool get estEntree =>
      this == TypeTransaction.cotisation || this == TypeTransaction.depot || this == TypeTransaction.remboursement;
}

enum StatutTransaction { effectue, en_attente, annule }

StatutTransaction statutTransactionFromString(String value) {
  return StatutTransaction.values.firstWhere(
    (s) => s.name == value,
    orElse: () => StatutTransaction.en_attente,
  );
}

/// Modèle Transaction — §4.2.5 du cahier des charges.
class TransactionModel {
  final String id;
  final String associationId;
  final String caisseId;
  final String membreId;
  final TypeTransaction type;
  final double montant;
  final String? description;
  final DateTime date;
  final StatutTransaction statut;
  final String reference;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.associationId,
    required this.caisseId,
    required this.membreId,
    required this.type,
    required this.montant,
    this.description,
    required this.date,
    this.statut = StatutTransaction.effectue,
    required this.reference,
    required this.createdAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      associationId: data['associationId'] as String? ?? '',
      caisseId: data['caisseId'] as String? ?? '',
      membreId: data['membreId'] as String? ?? '',
      type: typeTransactionFromString(data['type'] as String? ?? 'cotisation'),
      montant: (data['montant'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String?,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: statutTransactionFromString(data['statut'] as String? ?? 'effectue'),
      reference: data['reference'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'associationId': associationId,
      'caisseId': caisseId,
      'membreId': membreId,
      'type': type.name,
      'montant': montant,
      'description': description,
      'date': Timestamp.fromDate(date),
      'statut': statut.name,
      'reference': reference,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
