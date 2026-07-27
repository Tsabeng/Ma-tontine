import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutPret { en_attente, en_cours, solde, impaye, refuse }

StatutPret statutPretFromString(String value) {
  return StatutPret.values.firstWhere(
    (s) => s.name == value,
    orElse: () => StatutPret.en_attente,
  );
}

extension StatutPretLabel on StatutPret {
  String get label {
    switch (this) {
      case StatutPret.en_attente:
        return 'En attente de validation';
      case StatutPret.en_cours:
        return 'En cours';
      case StatutPret.solde:
        return 'Soldé';
      case StatutPret.impaye:
        return 'Impayé';
      case StatutPret.refuse:
        return 'Refusé';
    }
  }
}

/// Modèle Prêt (Loan) — §4.2.6 du cahier des charges.
class LoanModel {
  final String id;
  final String associationId;
  final String membreId;
  final double montant;
  final double tauxInteret;
  final int duree; // en mois
  final DateTime dateDebut;
  final DateTime dateFin;
  final double montantRembourse;
  final DateTime prochaineEcheance;
  final StatutPret statut;
  final double penalites;
  final DateTime createdAt;

  LoanModel({
    required this.id,
    required this.associationId,
    required this.membreId,
    required this.montant,
    required this.tauxInteret,
    required this.duree,
    required this.dateDebut,
    required this.dateFin,
    this.montantRembourse = 0,
    required this.prochaineEcheance,
    this.statut = StatutPret.en_cours,
    this.penalites = 0,
    required this.createdAt,
  });

  /// Montant total dû (capital + intérêts), calcul simple linéaire.
  double get montantTotalDu => montant + (montant * tauxInteret / 100);

  double get restantARembourser => (montantTotalDu + penalites) - montantRembourse;

  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoanModel(
      id: doc.id,
      associationId: data['associationId'] as String? ?? '',
      membreId: data['membreId'] as String? ?? '',
      montant: (data['montant'] as num?)?.toDouble() ?? 0,
      tauxInteret: (data['tauxInteret'] as num?)?.toDouble() ?? 0,
      duree: (data['duree'] as num?)?.toInt() ?? 0,
      dateDebut: (data['dateDebut'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateFin: (data['dateFin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      montantRembourse: (data['montantRembourse'] as num?)?.toDouble() ?? 0,
      prochaineEcheance: (data['prochaineEcheance'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: statutPretFromString(data['statut'] as String? ?? 'en_cours'),
      penalites: (data['penalites'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'associationId': associationId,
      'membreId': membreId,
      'montant': montant,
      'tauxInteret': tauxInteret,
      'duree': duree,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': Timestamp.fromDate(dateFin),
      'montantRembourse': montantRembourse,
      'prochaineEcheance': Timestamp.fromDate(prochaineEcheance),
      'statut': statut.name,
      'penalites': penalites,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
