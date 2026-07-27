import 'package:cloud_firestore/cloud_firestore.dart';

/// Wrapper générique autour de Firestore.
///
/// Centralise les noms de collections et fournit des raccourcis utilisés
/// par tous les autres services métier (association_service, meeting_service,
/// caisse_service, loan_service...). Toutes les collections "métier"
/// (meetings, caisses, transactions, loans) portent un champ `associationId`
/// qui garantit l'isolation des données par association — voir §1.3
/// (Attention : les données sont strictement isolées par association).
class FirestoreService {
  static final FirebaseFirestore instance = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get users =>
      instance.collection('users');

  static CollectionReference<Map<String, dynamic>> get associations =>
      instance.collection('associations');

  static CollectionReference<Map<String, dynamic>> get meetings =>
      instance.collection('meetings');

  static CollectionReference<Map<String, dynamic>> get caisses =>
      instance.collection('caisses');

  static CollectionReference<Map<String, dynamic>> get transactions =>
      instance.collection('transactions');

  static CollectionReference<Map<String, dynamic>> get loans =>
      instance.collection('loans');

  /// Sous-collection des membres d'une association donnée.
  /// (Les profils "membre" étendent le lien User<->Association avec des
  /// infos propres à l'association : adresse, photo, statut spécifique.)
  static CollectionReference<Map<String, dynamic>> membersOf(String associationId) =>
      associations.doc(associationId).collection('members');

  /// Requête de base filtrée par association — utilisée par tous les
  /// services métier pour respecter l'isolation multi-association (§1.3).
  static Query<Map<String, dynamic>> scopedTo(
    CollectionReference<Map<String, dynamic>> collection,
    String associationId,
  ) {
    return collection.where('associationId', isEqualTo: associationId);
  }
}
