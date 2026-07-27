import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../viewmodels/member_viewmodel.dart';
import '../../models/user_model.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  String? _associationIdChargee;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final associationId = context.watch<AssociationViewModel>().associationActive?.id;
    if (associationId != null && associationId != _associationIdChargee) {
      _associationIdChargee = associationId;
      context.read<MemberViewModel>().ecouterMembres(associationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MemberViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membres'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: vm.mettreAJourRecherche,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Rechercher un membre...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<MembreRole?>(
            icon: const Icon(Icons.filter_list),
            onSelected: vm.appliquerFiltreRole,
            itemBuilder: (context) => const [
              PopupMenuItem(value: null, child: Text('Tous les rôles')),
              PopupMenuItem(value: MembreRole.admin, child: Text('Administrateur')),
              PopupMenuItem(value: MembreRole.tresoriere, child: Text('Trésorière')),
              PopupMenuItem(value: MembreRole.secretaire, child: Text('Secrétaire')),
              PopupMenuItem(value: MembreRole.membre, child: Text('Membre')),
            ],
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: vm.membresFiltres.length,
              itemBuilder: (context, index) {
                final membre = vm.membresFiltres[index];
                return ListTile(
                  leading: CircleAvatar(child: Text((membre.nomComplet ?? '?').substring(0, 1).toUpperCase())),
                  title: Text(membre.nomComplet ?? 'Membre'),
                  subtitle: Text('${membre.role.name} · ${membre.statut.name}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'supprimer') {
                        final associationId = context.read<AssociationViewModel>().associationActive?.id;
                        if (associationId != null) vm.supprimerMembre(associationId, membre.uid);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                      PopupMenuItem(value: 'bilan', child: Text('Voir le bilan')),
                      PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _afficherFormulaireAjout(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _afficherFormulaireAjout(BuildContext context) {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Inviter un membre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom complet')),
            const SizedBox(height: 12),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final associationId = context.read<AssociationViewModel>().associationActive?.id;
                if (associationId != null && emailController.text.isNotEmpty) {
                  await context.read<MemberViewModel>().inviterParEmail(
                        associationId,
                        emailController.text.trim(),
                        MembreRole.membre,
                      );
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Envoyer l\'invitation'),
            ),
          ],
        ),
      ),
    );
  }
}
