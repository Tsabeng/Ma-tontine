import 'package:cloud_firestore/cloud_firestore.dart';

/// Rôle d'un utilisateur au sein d'une association.
enum MembreRole { admin, membre, tresoriere, secretaire }

MembreRole membreRoleFromString(String value) {
  return MembreRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => MembreRole.membre,
  );
}

enum StatutMembre { actif, inactif }

StatutMembre statutMembreFromString(String value) {
  return StatutMembre.values.firstWhere(
    (s) => s.name == value,
    orElse: () => StatutMembre.actif,
  );
}

/// Lien entre un utilisateur et une association (sous-document dans User).
class UserAssociationLink {
  final String associationId;
  final MembreRole role;
  final DateTime dateAdhesion;
  final StatutMembre statut;

  UserAssociationLink({
    required this.associationId,
    required this.role,
    required this.dateAdhesion,
    required this.statut,
  });

  factory UserAssociationLink.fromMap(Map<String, dynamic> map) {
    return UserAssociationLink(
      associationId: map['associationId'] as String,
      role: membreRoleFromString(map['role'] as String? ?? 'membre'),
      dateAdhesion: (map['dateAdhesion'] as Timestamp).toDate(),
      statut: statutMembreFromString(map['statut'] as String? ?? 'actif'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'associationId': associationId,
      'role': role.name,
      'dateAdhesion': Timestamp.fromDate(dateAdhesion),
      'statut': statut.name,
    };
  }
}

/// Modèle Utilisateur — §4.2.1 du cahier des charges.
class UserModel {
  final String uid;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String? photoURL;
  final DateTime createdAt;
  final List<UserAssociationLink> associations;

  UserModel({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.photoURL,
    required this.createdAt,
    this.associations = const [],
  });

  String get nomComplet => '$prenom $nom';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      email: data['email'] as String? ?? '',
      telephone: data['telephone'] as String? ?? '',
      photoURL: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      associations: (data['associations'] as List<dynamic>? ?? [])
          .map((e) => UserAssociationLink.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'associations': associations.map((a) => a.toMap()).toList(),
    };
  }

  UserModel copyWith({
    String? nom,
    String? prenom,
    String? telephone,
    String? photoURL,
    List<UserAssociationLink>? associations,
  }) {
    return UserModel(
      uid: uid,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email,
      telephone: telephone ?? this.telephone,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      associations: associations ?? this.associations,
    );
  }
}
