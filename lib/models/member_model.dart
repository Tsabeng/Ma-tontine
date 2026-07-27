import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/// Représente un membre au sein d'une association donnée (sous-collection
/// `associations/{id}/members`). Combine les infos du lien User<->Association
/// avec des champs propres à l'appartenance (adresse, photo). Référence §3.3.
class MemberModel {
  final String uid;
  final String? nomComplet;
  final String? email;
  final String? telephone;
  final String? adresse;
  final String? photo;
  final MembreRole role;
  final StatutMembre statut;
  final DateTime dateAdhesion;

  MemberModel({
    required this.uid,
    this.nomComplet,
    this.email,
    this.telephone,
    this.adresse,
    this.photo,
    required this.role,
    required this.statut,
    required this.dateAdhesion,
  });

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      uid: doc.id,
      nomComplet: data['nomComplet'] as String?,
      email: data['email'] as String?,
      telephone: data['telephone'] as String?,
      adresse: data['adresse'] as String?,
      photo: data['photo'] as String?,
      role: membreRoleFromString(data['role'] as String? ?? 'membre'),
      statut: statutMembreFromString(data['statut'] as String? ?? 'actif'),
      dateAdhesion: (data['dateAdhesion'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nomComplet': nomComplet,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'photo': photo,
      'role': role.name,
      'statut': statut.name,
      'dateAdhesion': Timestamp.fromDate(dateAdhesion),
    };
  }
}
