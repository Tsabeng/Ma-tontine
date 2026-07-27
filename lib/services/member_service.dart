import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Gère les membres d'une association : ajout direct, invitation par
/// email, liste avec recherche/filtrage/tri. Référence : §3.3.
class MemberService {
  /// Ajout direct d'un membre (déjà connu, sans passer par le code
  /// d'invitation) — §3.3.1.
  Future<void> ajouterMembre({
    required String associationId,
    required String uid,
    String? nomComplet,
    String? email,
    String? telephone,
    String? adresse,
    MembreRole role = MembreRole.membre,
  }) async {
    final now = DateTime.now();
    final member = MemberModel(
      uid: uid,
      nomComplet: nomComplet,
      email: email,
      telephone: telephone,
      adresse: adresse,
      role: role,
      statut: StatutMembre.actif,
      dateAdhesion: now,
    );

    final batch = FirestoreService.instance.batch();
    batch.set(FirestoreService.membersOf(associationId).doc(uid), member.toMap());
    batch.update(FirestoreService.users.doc(uid), {
      'associations': FieldValue.arrayUnion([
        UserAssociationLink(
          associationId: associationId,
          role: role,
          dateAdhesion: now,
          statut: StatutMembre.actif,
        ).toMap(),
      ]),
    });
    await batch.commit();
  }

  /// Invitation d'un membre par email — §3.3.1. En production, ceci
  /// déclenche une Cloud Function qui envoie l'email d'invitation ;
  /// ici on enregistre la demande en attente.
  Future<void> inviterParEmail({
    required String associationId,
    required String email,
    MembreRole role = MembreRole.membre,
  }) async {
    await FirestoreService.associations
        .doc(associationId)
        .collection('invitations_en_attente')
        .add({
      'email': email,
      'role': role.name,
      'invitedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<MemberModel>> watchMembres(String associationId) {
    return FirestoreService.membersOf(associationId)
        .orderBy('dateAdhesion', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MemberModel.fromFirestore).toList());
  }

  Future<void> modifierRole(String associationId, String uid, MembreRole role) {
    return FirestoreService.membersOf(associationId).doc(uid).update({'role': role.name});
  }

  Future<void> modifierStatut(String associationId, String uid, StatutMembre statut) {
    return FirestoreService.membersOf(associationId).doc(uid).update({'statut': statut.name});
  }

  Future<void> supprimerMembre(String associationId, String uid) {
    return FirestoreService.membersOf(associationId).doc(uid).delete();
  }
}
