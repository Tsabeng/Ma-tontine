import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutAssociation { active, fermee }

StatutAssociation statutAssociationFromString(String value) {
  return StatutAssociation.values.firstWhere(
    (s) => s.name == value,
    orElse: () => StatutAssociation.active,
  );
}

/// Modèle Association — §4.2.2 du cahier des charges.
///
/// Une association est l'entité racine autour de laquelle toutes les
/// données (membres, réunions, caisses, transactions) sont isolées.
class AssociationModel {
  final String id;
  final String nom;
  final String? description;
  final String? logo;
  final String? pays;
  final String? ville;
  final String? email;
  final String? telephone;
  final DateTime dateCreation;
  final StatutAssociation statut;
  final String createdBy;
  final DateTime createdAt;
  final String codeInvitation;
  final DateTime? updatedAt;

  // Champs dérivés utiles pour l'affichage (§3.2.3), non stockés tels quels
  // mais calculés côté service à partir des sous-collections.
  final int nombreMembres;

  AssociationModel({
    required this.id,
    required this.nom,
    this.description,
    this.logo,
    this.pays,
    this.ville,
    this.email,
    this.telephone,
    required this.dateCreation,
    this.statut = StatutAssociation.active,
    required this.createdBy,
    required this.createdAt,
    required this.codeInvitation,
    this.updatedAt,
    this.nombreMembres = 0,
  });

  factory AssociationModel.fromFirestore(DocumentSnapshot doc, {int nombreMembres = 0}) {
    final data = doc.data() as Map<String, dynamic>;
    return AssociationModel(
      id: doc.id,
      nom: data['nom'] as String? ?? '',
      description: data['description'] as String?,
      logo: data['logo'] as String?,
      pays: data['pays'] as String?,
      ville: data['ville'] as String?,
      email: data['email'] as String?,
      telephone: data['telephone'] as String?,
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: statutAssociationFromString(data['statut'] as String? ?? 'active'),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      codeInvitation: data['codeInvitation'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      nombreMembres: nombreMembres,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
      'logo': logo,
      'pays': pays,
      'ville': ville,
      'email': email,
      'telephone': telephone,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'statut': statut.name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'codeInvitation': codeInvitation,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
