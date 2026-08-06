import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../viewmodels/meeting_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/meeting_model.dart';

/// Formulaire de création OU de modification d'une réunion. Si une
/// [MeetingModel] est passée en argument de route
/// (`Navigator.pushNamed(..., arguments: meeting)`), l'écran s'ouvre en
/// mode édition, préremplit les champs et appelle `modifierReunion` au
/// lieu de `creerReunion`.
class MeetingFormScreen extends StatefulWidget {
  const MeetingFormScreen({super.key});

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lieuController = TextEditingController();
  final _lienController = TextEditingController();
  final _fraisController = TextEditingController();
  final _ordreJourController = TextEditingController();

  DateTime _date = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _heure = const TimeOfDay(hour: 15, minute: 0);
  TypeReunion _type = TypeReunion.presentiel;
  bool _isSaving = false;
  bool _champsPreremplis = false;
  MeetingModel? _meetingExistante;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_champsPreremplis) return;
    final meeting = ModalRoute.of(context)?.settings.arguments as MeetingModel?;
    if (meeting != null) {
      _meetingExistante = meeting;
      _titreController.text = meeting.titre;
      _descriptionController.text = meeting.description ?? '';
      _lieuController.text = meeting.lieu;
      _lienController.text = meeting.lien ?? '';
      _fraisController.text = meeting.fraisPresence?.toStringAsFixed(0) ?? '';
      _ordreJourController.text = meeting.ordreJour.join('\n');
      _date = meeting.date;
      final parts = meeting.heure.split(':');
      if (parts.length == 2) {
        _heure = TimeOfDay(hour: int.tryParse(parts[0]) ?? 15, minute: int.tryParse(parts[1]) ?? 0);
      }
      _type = meeting.type;
    }
    _champsPreremplis = true;
  }

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _choisirHeure() async {
    final picked = await showTimePicker(context: context, initialTime: _heure);
    if (picked != null) setState(() => _heure = picked);
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    final association = context.read<AssociationViewModel>().associationActive;
    final uid = context.read<AuthViewModel>().currentUser?.uid;
    if (association == null || uid == null) return;

    setState(() => _isSaving = true);

    final ordreJour = _ordreJourController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final heureFormatee = '${_heure.hour.toString().padLeft(2, '0')}:${_heure.minute.toString().padLeft(2, '0')}';
    final vm = context.read<MeetingViewModel>();
    bool ok;

    if (_meetingExistante != null) {
      final meetingModifiee = MeetingModel(
        id: _meetingExistante!.id,
        associationId: _meetingExistante!.associationId,
        caisseId: _meetingExistante!.caisseId,
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        date: _date,
        heure: heureFormatee,
        lieu: _lieuController.text.trim(),
        type: _type,
        lien: _type == TypeReunion.en_ligne ? _lienController.text.trim() : null,
        ordreJour: ordreJour,
        fraisPresence: double.tryParse(_fraisController.text),
        statut: _meetingExistante!.statut,
        createdBy: _meetingExistante!.createdBy,
        createdAt: _meetingExistante!.createdAt,
        participants: _meetingExistante!.participants,
        presences: _meetingExistante!.presences,
        compteRendu: _meetingExistante!.compteRendu,
        pdfUrl: _meetingExistante!.pdfUrl,
      );
      ok = await vm.modifierReunion(meetingModifiee);
    } else {
      final meeting = MeetingModel(
        id: '',
        associationId: association.id,
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        date: _date,
        heure: heureFormatee,
        lieu: _lieuController.text.trim(),
        type: _type,
        lien: _type == TypeReunion.en_ligne ? _lienController.text.trim() : null,
        ordreJour: ordreJour,
        fraisPresence: double.tryParse(_fraisController.text),
        createdBy: uid,
        createdAt: DateTime.now(),
      );
      ok = await vm.creerReunion(meeting);
    }

    setState(() => _isSaving = false);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MeetingViewModel>();
    final modeEdition = _meetingExistante != null;

    return Scaffold(
      appBar: AppBar(title: Text(modeEdition ? 'Modifier la réunion' : 'Nouvelle réunion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(labelText: 'Titre *'),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Date : ${_date.day}/${_date.month}/${_date.year}'),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                      onTap: _choisirDate,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Heure : ${_heure.format(context)}'),
                      trailing: const Icon(Icons.access_time, size: 18),
                      onTap: _choisirHeure,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _lieuController,
                decoration: const InputDecoration(labelText: 'Lieu *'),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 16),
              SegmentedButton<TypeReunion>(
                segments: const [
                  ButtonSegment(value: TypeReunion.presentiel, label: Text('Présentiel')),
                  ButtonSegment(value: TypeReunion.en_ligne, label: Text('En ligne')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              if (_type == TypeReunion.en_ligne) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lienController,
                  decoration: const InputDecoration(labelText: 'Lien de la réunion'),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _fraisController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Frais de présence (FCFA)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ordreJourController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Ordre du jour",
                  hintText: 'Un point par ligne',
                ),
              ),
              const SizedBox(height: 24),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: _isSaving ? null : _enregistrer,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(modeEdition ? 'Enregistrer les modifications' : 'Créer la réunion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}