import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../config/routes.dart';
import '../association_selector/association_selector_drawer_item.dart';

/// Menu latéral (Drawer) — reproduit le wireframe §7.1.3 :
/// profil, navigation principale, et sélecteur rapide d'association
/// permettant le basculement décrit en §2.2.2 / §3.2.4.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final associationVm = context.watch<AssociationViewModel>();
    final user = auth.currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(user != null && user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : '?'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.nomComplet ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Tableau de bord'),
              onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Membres'),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.members),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Réunions'),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.meetings),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Finances'),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.finances),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Changer d'association", style: Theme.of(context).textTheme.labelLarge),
            ),
            ...associationVm.mesAssociations.map(
              (a) => AssociationSelectorDrawerItem(
                association: a,
                estActive: associationVm.associationActive?.id == a.id,
                onTap: () async {
                  await associationVm.selectionnerAssociation(a);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                  }
                },
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Voir toutes mes associations'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.associationSelection),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Paramètres'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Aide'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await auth.deconnexion();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
