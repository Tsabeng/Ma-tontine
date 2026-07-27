import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeReunion { presentiel, en_ligne }

TypeReunion typeReunionFromString(String value) {
  return TypeReunion.values.firstWhere(
    (t) => t.name == value,
    orElse: () => TypeReunion.presentiel,
  );
}

enum StatutReunion { planifie, en_cours, termine }

StatutReunion statutReunionFromString(String value) {
  return StatutReunion.values.firstWhere(
    (s) => s.name == value,
    orElse: () => StatutReunion.planifie,
  );
}

/// Modèle Réunion — §4.2.3 du cahier des charges.
class MeetingModel {
  final String id;
  final String associationId;
  final String? caisseId;
  final String titre;
  final String? description;
  final DateTime date;
  final String heure;
  final String lieu;
  final TypeReunion type;
  final String? lien;
  final List<String> ordreJour;
  final double? fraisPresence;
  final StatutReunion statut;
  final String createdBy;
  final DateTime createdAt;
  final List<String> participants;
  final List<String> presences;
  final String? compteRendu;
  final String? pdfUrl;

  MeetingModel({
    required this.id,
    required this.associationId,
    this.caisseId,
    required this.titre,
    this.description,
    required this.date,
    required this.heure,
    required this.lieu,
    this.type = TypeReunion.presentiel,
    this.lien,
    this.ordreJour = const [],
    this.fraisPresence,
    this.statut = StatutReunion.planifie,
    required this.createdBy,
    required this.createdAt,
    this.participants = const [],
    this.presences = const [],
    this.compteRendu,
    this.pdfUrl,
  });

  factory MeetingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeetingModel(
      id: doc.id,
      associationId: data['associationId'] as String? ?? '',
      caisseId: data['caisseId'] as String?,
      titre: data['titre'] as String? ?? '',
      description: data['description'] as String?,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      heure: data['heure'] as String? ?? '',
      lieu: data['lieu'] as String? ?? '',
      type: typeReunionFromString(data['type'] as String? ?? 'presentiel'),
      lien: data['lien'] as String?,
      ordreJour: List<String>.from(data['ordreJour'] as List<dynamic>? ?? []),
      fraisPresence: (data['fraisPresence'] as num?)?.toDouble(),
      statut: statutReunionFromString(data['statut'] as String? ?? 'planifie'),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participants: List<String>.from(data['participants'] as List<dynamic>? ?? []),
      presences: List<String>.from(data['presences'] as List<dynamic>? ?? []),
      compteRendu: data['compteRendu'] as String?,
      pdfUrl: data['pdfUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'associationId': associationId,
      'caisseId': caisseId,
      'titre': titre,
      'description': description,
      'date': Timestamp.fromDate(date),
      'heure': heure,
      'lieu': lieu,
      'type': type.name,
      'lien': lien,
      'ordreJour': ordreJour,
      'fraisPresence': fraisPresence,
      'statut': statut.name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'participants': participants,
      'presences': presences,
      'compteRendu': compteRendu,
      'pdfUrl': pdfUrl,
    };
  }
}
