import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

/// Gère les membres d'une association : ajout par informations (avec
/// création automatique de compte si besoin), liste avec
/// recherche/filtrage/tri. Référence : §3.3.
class MemberService {
  final AuthService _authService;

  MemberService(this._authService);

  /// Ajout direct d'un membre (déjà connu dans l'app, avec son uid) —
  /// utilisé en interne par [ajouterMembreParInformations].
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

  /// Ajoute un membre uniquement à partir de ses informations (nom, email,
  /// téléphone, adresse). Si aucun compte n'existe pour cet email, il est
  /// créé automatiquement ; le membre reçoit un email pour définir son
  /// propre mot de passe et pourra se connecter plus tard. Remplace le
  /// workflow d'invitation par email — §3.3.1.
  Future<void> ajouterMembreParInformations({
    required String associationId,
    required String nomComplet,
    required String email,
    String? telephone,
    String? adresse,
    MembreRole role = MembreRole.membre,
  }) async {
    // 1. Cherche si un compte existe déjà pour cet email (parmi les
    // profils déjà créés dans l'app).
    final query = await FirestoreService.users.where('email', isEqualTo: email).limit(1).get();

    final String uid;
    if (query.docs.isNotEmpty) {
      uid = query.docs.first.id;
    } else {
      // 2. Sinon, crée automatiquement le compte du nouveau membre.
      uid = await _authService.creerCompteMembreParAdmin(email: email, nomComplet: nomComplet);
    }

    // 3. Rattache le membre à l'association.
    await ajouterMembre(
      associationId: associationId,
      uid: uid,
      nomComplet: nomComplet,
      email: email,
      telephone: telephone,
      adresse: adresse,
      role: role,
    );
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