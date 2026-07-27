import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/association_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Gère le cycle de vie des associations : création, invitation,
/// rejoindre, sélection et basculement. Référence : §3.2.
class AssociationService {
  final _db = FirestoreService.instance;

  /// Génère un code d'invitation unique au format ABCD-EFGH.
  String _genererCodeInvitation() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sans O/0/I/1 ambigus
    final rand = Random.secure();
    String bloc() => List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return '${bloc()}-${bloc()}';
  }

  /// Création d'une association — §3.2.1.
  /// Le créateur devient automatiquement administrateur.
  Future<AssociationModel> creerAssociation({
    required String uid,
    required String nom,
    String? description,
    String? logo,
    String? pays,
    String? ville,
    String? email,
    String? telephone,
  }) async {
    final docRef = FirestoreService.associations.doc();
    final now = DateTime.now();

    final association = AssociationModel(
      id: docRef.id,
      nom: nom,
      description: description,
      logo: logo,
      pays: pays,
      ville: ville,
      email: email,
      telephone: telephone,
      dateCreation: now,
      createdBy: uid,
      createdAt: now,
      codeInvitation: _genererCodeInvitation(),
    );

    final batch = _db.batch();
    batch.set(docRef, association.toMap());

    // Lien utilisateur -> association avec rôle admin.
    final userRef = FirestoreService.users.doc(uid);
    batch.update(userRef, {
      'associations': FieldValue.arrayUnion([
        UserAssociationLink(
          associationId: docRef.id,
          role: MembreRole.admin,
          dateAdhesion: now,
          statut: StatutMembre.actif,
        ).toMap(),
      ]),
    });

    // Le créateur est aussi ajouté à la sous-collection members.
    final memberRef = FirestoreService.membersOf(docRef.id).doc(uid);
    batch.set(memberRef, {
      'uid': uid,
      'role': MembreRole.admin.name,
      'statut': StatutMembre.actif.name,
      'dateAdhesion': Timestamp.fromDate(now),
    });

    await batch.commit();
    return association;
  }

  /// Rejoindre une association via code d'invitation — §3.2.2.
  Future<AssociationModel> rejoindreParCode({
    required String uid,
    required String code,
  }) async {
    final query = await FirestoreService.associations
        .where('codeInvitation', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Code d'invitation invalide.");
    }

    final doc = query.docs.first;
    final association = AssociationModel.fromFirestore(doc);
    final now = DateTime.now();

    final batch = _db.batch();

    batch.update(FirestoreService.users.doc(uid), {
      'associations': FieldValue.arrayUnion([
        UserAssociationLink(
          associationId: association.id,
          role: MembreRole.membre,
          dateAdhesion: now,
          statut: StatutMembre.actif,
        ).toMap(),
      ]),
    });

    batch.set(FirestoreService.membersOf(association.id).doc(uid), {
      'uid': uid,
      'role': MembreRole.membre.name,
      'statut': StatutMembre.actif.name,
      'dateAdhesion': Timestamp.fromDate(now),
    });

    await batch.commit();

    // TODO(notification_service): notifier l'administrateur du nouveau membre.
    return association;
  }

  /// Liste des associations d'un utilisateur, avec nombre de membres —
  /// alimente l'écran de sélection (§3.2.3).
  Future<List<AssociationModel>> listerAssociationsUtilisateur(List<String> ids) async {
    if (ids.isEmpty) return [];
    final results = <AssociationModel>[];

    // Firestore limite whereIn à 30 éléments ; on chunk par sécurité.
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await FirestoreService.associations
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snap.docs) {
        final membersCount = await FirestoreService.membersOf(doc.id).count().get();
        results.add(AssociationModel.fromFirestore(doc, nombreMembres: membersCount.count ?? 0));
      }
    }
    return results;
  }

  Future<AssociationModel> getAssociation(String id) async {
    final doc = await FirestoreService.associations.doc(id).get();
    return AssociationModel.fromFirestore(doc);
  }

  Stream<AssociationModel> watchAssociation(String id) {
    return FirestoreService.associations.doc(id).snapshots().map(
          (doc) => AssociationModel.fromFirestore(doc),
        );
  }
}
