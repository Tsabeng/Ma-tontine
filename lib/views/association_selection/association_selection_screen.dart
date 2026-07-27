import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../models/association_model.dart';
import '../../models/user_model.dart';
import '../../config/routes.dart';

/// Écran "Mes Associations" — fidèle au wireframe §7.1.1.
/// Affiche toutes les associations de l'utilisateur, met en avant la
/// dernière utilisée, et permet de créer ou rejoindre une association.
class AssociationSelectionScreen extends StatefulWidget {
  const AssociationSelectionScreen({super.key});

  @override
  State<AssociationSelectionScreen> createState() => _AssociationSelectionScreenState();
}

class _AssociationSelectionScreenState extends State<AssociationSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;
    final ids = user.associations.map((a) => a.associationId).toList();
    await context.read<AssociationViewModel>().chargerAssociations(ids);
  }

  String _roleLabel(UserModel user, String associationId) {
    final lien = user.associations.where((a) => a.associationId == associationId);
    if (lien.isEmpty) return 'Membre';
    switch (lien.first.role) {
      case MembreRole.admin:
        return 'Administrateur';
      case MembreRole.tresoriere:
        return 'Trésorière';
      case MembreRole.secretaire:
        return 'Secrétaire';
      case MembreRole.membre:
        return 'Membre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<AssociationViewModel>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Associations')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (user != null) ...[
                    Text('Bonjour ${user.prenom}', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('${vm.mesAssociations.length} association(s)', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 20),
                  ],
                  ...vm.mesAssociations.map((association) {
                    final estDerniere = vm.associationActive?.id == association.id;
                    return _AssociationCard(
                      association: association,
                      role: user != null ? _roleLabel(user, association.id) : 'Membre',
                      estDerniere: estDerniere,
                      onOuvrir: () async {
                        await vm.selectionnerAssociation(association);
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.group_add),
                    label: const Text('Rejoindre une association'),
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.joinAssociation),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une association'),
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.associationCreation),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AssociationCard extends StatelessWidget {
  final AssociationModel association;
  final String role;
  final bool estDerniere;
  final VoidCallback onOuvrir;

  const _AssociationCard({
    required this.association,
    required this.role,
    required this.estDerniere,
    required this.onOuvrir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          child: Text(
            association.nom.isNotEmpty ? association.nom[0].toUpperCase() : '?',
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Flexible(child: Text(association.nom, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (estDerniere) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Dernière', style: TextStyle(fontSize: 11)),
              ),
            ],
          ],
        ),
        subtitle: Text('${association.nombreMembres} membres · $role'),
        trailing: TextButton(onPressed: onOuvrir, child: const Text('Ouvrir')),
        onTap: onOuvrir,
      ),
    );
  }
}
