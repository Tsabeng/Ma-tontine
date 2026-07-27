import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';
import 'firestore_service.dart';

/// Gère les réunions d'une association active. Référence : §3.4.
class MeetingService {
  /// Création d'une réunion — §3.4.1.
  Future<MeetingModel> creerReunion(MeetingModel meeting) async {
    final docRef = FirestoreService.meetings.doc();
    final withId = MeetingModel(
      id: docRef.id,
      associationId: meeting.associationId,
      caisseId: meeting.caisseId,
      titre: meeting.titre,
      description: meeting.description,
      date: meeting.date,
      heure: meeting.heure,
      lieu: meeting.lieu,
      type: meeting.type,
      lien: meeting.lien,
      ordreJour: meeting.ordreJour,
      fraisPresence: meeting.fraisPresence,
      createdBy: meeting.createdBy,
      createdAt: DateTime.now(),
    );
    await docRef.set(withId.toMap());
    // TODO(notification_service): notifier les membres de la nouvelle réunion.
    return withId;
  }

  /// Réunions d'une association, triées par date — écran liste.
  Stream<List<MeetingModel>> watchReunions(String associationId) {
    return FirestoreService.scopedTo(FirestoreService.meetings, associationId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MeetingModel.fromFirestore).toList());
  }

  Future<MeetingModel> getReunion(String id) async {
    final doc = await FirestoreService.meetings.doc(id).get();
    return MeetingModel.fromFirestore(doc);
  }

  /// Un membre confirme sa participation — §3.4.2 (bouton "Participer").
  Future<void> participer(String meetingId, String uid) async {
    await FirestoreService.meetings.doc(meetingId).update({
      'participants': FieldValue.arrayUnion([uid]),
    });
  }

  /// L'administrateur marque les présences réelles — §3.4.2.
  Future<void> marquerPresence(String meetingId, List<String> uidsPresents) async {
    await FirestoreService.meetings.doc(meetingId).update({
      'presences': uidsPresents,
    });
  }

  /// Enregistre le compte-rendu et clôture la réunion.
  Future<void> cloturerAvecCompteRendu({
    required String meetingId,
    required String compteRendu,
  }) async {
    await FirestoreService.meetings.doc(meetingId).update({
      'compteRendu': compteRendu,
      'statut': 'termine',
    });
    // TODO(notification_service): envoyer le compte-rendu après la réunion.
  }
}
