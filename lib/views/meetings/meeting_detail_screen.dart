import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/meeting_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/pdf_service.dart';
import '../../services/meeting_service.dart';
import '../../models/meeting_model.dart';

/// Détail d'une réunion : ordre du jour, participants, présences,
/// compte-rendu, export PDF. Référence : §3.4.2.
///
/// L'ID de la réunion est transmis via `ModalRoute` arguments lors de la
/// navigation (`Navigator.pushNamed(..., arguments: meetingId)`).
class MeetingDetailScreen extends StatelessWidget {
  const MeetingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meetingId = ModalRoute.of(context)!.settings.arguments as String;
    final meetingVm = context.watch<MeetingViewModel>();
    final meeting = meetingVm.reunions.where((r) => r.id == meetingId).isNotEmpty
        ? meetingVm.reunions.firstWhere((r) => r.id == meetingId)
        : null;

    if (meeting == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final uid = context.watch<AuthViewModel>().currentUser?.uid;
    final dejaParticipant = uid != null && meeting.participants.contains(uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(meeting.titre),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exporter en PDF',
            onPressed: () async {
              final file = await PdfService().genererCompteRenduPdf(meeting);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PDF généré : ${file.path}')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(meeting.date)} à ${meeting.heure}'),
          const SizedBox(height: 4),
          Text(meeting.type == TypeReunion.en_ligne ? 'En ligne — ${meeting.lien ?? ''}' : meeting.lieu),
          if (meeting.description != null) ...[
            const SizedBox(height: 16),
            Text(meeting.description!),
          ],
          const SizedBox(height: 24),
          if (meeting.ordreJour.isNotEmpty) ...[
            Text('Ordre du jour', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...meeting.ordreJour.map((p) => ListTile(dense: true, leading: const Icon(Icons.circle, size: 8), title: Text(p))),
            const SizedBox(height: 16),
          ],
          Text('Participants (${meeting.participants.length}) · Présents (${meeting.presences.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (uid != null && !dejaParticipant)
            ElevatedButton.icon(
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Participer'),
              onPressed: () => context.read<MeetingViewModel>().participer(meeting.id, uid),
            ),
          const SizedBox(height: 24),
          Text('Compte-rendu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(meeting.compteRendu ?? 'Aucun compte-rendu saisi pour le moment.'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _afficherFormulaireCompteRendu(context, meeting),
            child: const Text('Rédiger / modifier le compte-rendu'),
          ),
        ],
      ),
    );
  }

  void _afficherFormulaireCompteRendu(BuildContext context, MeetingModel meeting) {
    final controller = TextEditingController(text: meeting.compteRendu ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Compte-rendu de la réunion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(controller: controller, maxLines: 6, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await MeetingService().cloturerAvecCompteRendu(meetingId: meeting.id, compteRendu: controller.text);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
