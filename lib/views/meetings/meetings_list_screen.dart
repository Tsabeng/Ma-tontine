import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../viewmodels/meeting_viewmodel.dart';
import '../../models/meeting_model.dart';
import '../../config/routes.dart';

class MeetingsListScreen extends StatelessWidget {
  const MeetingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MeetingViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Réunions')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.reunions.isEmpty
              ? const Center(child: Text('Aucune réunion pour le moment'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: vm.reunions.length,
                  itemBuilder: (context, index) {
                    final r = vm.reunions[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statutColor(r.statut).withOpacity(0.15),
                          child: Icon(Icons.event, color: _statutColor(r.statut)),
                        ),
                        title: Text(r.titre),
                        subtitle: Text('${DateFormat('dd/MM/yyyy').format(r.date)} à ${r.heure} · ${r.lieu}'),
                        trailing: Text(_statutLabel(r.statut)),
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.meetingDetail, arguments: r.id),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.meetingForm),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle réunion'),
      ),
    );
  }

  Color _statutColor(StatutReunion statut) {
    switch (statut) {
      case StatutReunion.planifie:
        return Colors.blue;
      case StatutReunion.en_cours:
        return Colors.orange;
      case StatutReunion.termine:
        return Colors.green;
    }
  }

  String _statutLabel(StatutReunion statut) {
    switch (statut) {
      case StatutReunion.planifie:
        return 'Planifiée';
      case StatutReunion.en_cours:
        return 'En cours';
      case StatutReunion.termine:
        return 'Terminée';
    }
  }
}
