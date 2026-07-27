import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/meeting_model.dart';
import '../models/transaction_model.dart';

/// Génère les exports PDF/CSV : comptes-rendus de réunion et historiques
/// de transactions. Référence : §3.4.2 (compte-rendu), §3.5.3 (export).
class PdfService {
  /// Génère le PDF du compte-rendu d'une réunion et retourne le fichier local.
  Future<File> genererCompteRenduPdf(MeetingModel meeting) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Compte-rendu — ${meeting.titre}',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Date : ${meeting.date.day}/${meeting.date.month}/${meeting.date.year} à ${meeting.heure}'),
            pw.Text('Lieu : ${meeting.lieu}'),
            pw.SizedBox(height: 16),
            pw.Text('Ordre du jour', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...meeting.ordreJour.map((point) => pw.Bullet(text: point)),
            pw.SizedBox(height: 16),
            pw.Text('Présences', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('${meeting.presences.length} membre(s) présent(s) sur ${meeting.participants.length} inscrit(s)'),
            pw.SizedBox(height: 16),
            pw.Text('Compte-rendu', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(meeting.compteRendu ?? 'Aucun compte-rendu saisi.'),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/compte_rendu_${meeting.id}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  /// Exporte l'historique des transactions d'une caisse en PDF —
  /// §3.5.3 "Exporter les transactions en PDF/CSV".
  Future<File> exporterTransactionsPdf(String nomCaisse, List<TransactionModel> transactions) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Historique — $nomCaisse', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['Date', 'Type', 'Montant', 'Statut', 'Référence'],
            data: transactions.map((t) => [
                  '${t.date.day}/${t.date.month}/${t.date.year}',
                  t.type.name,
                  t.montant.toStringAsFixed(0),
                  t.statut.name,
                  t.reference,
                ]).toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/transactions_$nomCaisse.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  /// Exporte l'historique des transactions d'une caisse en CSV —
  /// alternative légère au PDF pour l'analyse en tableur.
  Future<File> exporterTransactionsCsv(String nomCaisse, List<TransactionModel> transactions) async {
    final rows = <List<String>>[
      ['Date', 'Type', 'Montant', 'Statut', 'Référence', 'Description'],
      ...transactions.map((t) => [
            '${t.date.day}/${t.date.month}/${t.date.year}',
            t.type.name,
            t.montant.toStringAsFixed(0),
            t.statut.name,
            t.reference,
            t.description ?? '',
          ]),
    ];

    final csvContent = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/transactions_$nomCaisse.csv');
    await file.writeAsString(csvContent);
    return file;
  }
}
