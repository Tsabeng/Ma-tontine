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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<MemberViewModel>().ecouterMembres(associationId);
      });
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
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final telephoneController = TextEditingController();
    final adresseController = TextEditingController();
    MembreRole roleSelectionne = MembreRole.membre;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final vm = ctx.watch<MemberViewModel>();
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ajouter un membre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    const Text(
                      "Si cette personne n'a pas encore de compte, il sera créé "
                      "automatiquement et elle recevra un email pour choisir son mot de passe.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nomController,
                      decoration: const InputDecoration(labelText: 'Nom complet *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email *'),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: adresseController,
                      decoration: const InputDecoration(labelText: 'Adresse (optionnel)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MembreRole>(
                      initialValue: roleSelectionne,
                      decoration: const InputDecoration(labelText: 'Rôle'),
                      items: const [
                        DropdownMenuItem(value: MembreRole.membre, child: Text('Membre')),
                        DropdownMenuItem(value: MembreRole.tresoriere, child: Text('Trésorière')),
                        DropdownMenuItem(value: MembreRole.secretaire, child: Text('Secrétaire')),
                        DropdownMenuItem(value: MembreRole.admin, child: Text('Administrateur')),
                      ],
                      onChanged: (v) => setState(() => roleSelectionne = v ?? roleSelectionne),
                    ),
                    const SizedBox(height: 16),
                    if (vm.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    ElevatedButton(
                      onPressed: vm.isCreatingMember
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final associationId = ctx.read<AssociationViewModel>().associationActive?.id;
                              if (associationId == null) return;

                              final ok = await vm.ajouterMembreParInformations(
                                associationId: associationId,
                                nomComplet: nomController.text.trim(),
                                email: emailController.text.trim(),
                                telephone: telephoneController.text.trim().isEmpty ? null : telephoneController.text.trim(),
                                adresse: adresseController.text.trim().isEmpty ? null : adresseController.text.trim(),
                                role: roleSelectionne,
                              );
                              if (ok && ctx.mounted) Navigator.of(ctx).pop();
                            },
                      child: vm.isCreatingMember
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Ajouter le membre'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}