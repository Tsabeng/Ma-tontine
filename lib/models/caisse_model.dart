import 'package:cloud_firestore/cloud_firestore.dart';

/// Types de caisses définis en §3.5.1
enum TypeCaisse { solidarite, projets, scolaire, epargne, tontine, personnalise }

TypeCaisse typeCaisseFromString(String value) {
  return TypeCaisse.values.firstWhere(
    (t) => t.name == value,
    orElse: () => TypeCaisse.personnalise,
  );
}

extension TypeCaisseLabel on TypeCaisse {
  String get label {
    switch (this) {
      case TypeCaisse.solidarite:
        return 'Caisse Solidarité';
      case TypeCaisse.projets:
        return 'Caisse Projets';
      case TypeCaisse.scolaire:
        return 'Caisse Scolaire';
      case TypeCaisse.epargne:
        return 'Caisse Épargne';
      case TypeCaisse.tontine:
        return 'Tontine';
      case TypeCaisse.personnalise:
        return 'Caisse Personnalisée';
    }
  }
}

enum StatutCaisse { active, fermee }

StatutCaisse statutCaisseFromString(String value) {
  return StatutCaisse.values.firstWhere(
    (s) => s.name == value,
    orElse: () => StatutCaisse.active,
  );
}

/// Modèle Caisse — §4.2.4 du cahier des charges.
class CaisseModel {
  final String id;
  final String associationId;
  final String nom;
  final TypeCaisse type;
  final String? description;
  final double? objectif;
  final double solde;
  final DateTime createdAt;
  final String createdBy;
  final List<String> contributeurs;
  final StatutCaisse statut;
  final DateTime? updatedAt;

  CaisseModel({
    required this.id,
    required this.associationId,
    required this.nom,
    required this.type,
    this.description,
    this.objectif,
    this.solde = 0,
    required this.createdAt,
    required this.createdBy,
    this.contributeurs = const [],
    this.statut = StatutCaisse.active,
    this.updatedAt,
  });

  factory CaisseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CaisseModel(
      id: doc.id,
      associationId: data['associationId'] as String? ?? '',
      nom: data['nom'] as String? ?? '',
      type: typeCaisseFromString(data['type'] as String? ?? 'personnalise'),
      description: data['description'] as String?,
      objectif: (data['objectif'] as num?)?.toDouble(),
      solde: (data['solde'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
      contributeurs: List<String>.from(data['contributeurs'] as List<dynamic>? ?? []),
      statut: statutCaisseFromString(data['statut'] as String? ?? 'active'),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'associationId': associationId,
      'nom': nom,
      'type': type.name,
      'description': description,
      'objectif': objectif,
      'solde': solde,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'contributeurs': contributeurs,
      'statut': statut.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
