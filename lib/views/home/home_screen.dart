import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../viewmodels/meeting_viewmodel.dart';
import '../../viewmodels/caisse_viewmodel.dart';
import '../../viewmodels/loan_viewmodel.dart';
import '../../widgets/common/app_drawer.dart';
import '../../config/routes.dart';

final _formatFcfa = NumberFormat.decimalPattern('fr_FR');

/// Tableau de bord de l'association sélectionnée — fidèle au wireframe
/// §7.1.2. Toutes les données affichées sont relatives à l'association
/// active uniquement (isolation stricte, §1.3).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _dernierAssociationIdChargee;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final associationId = context.watch<AssociationViewModel>().associationActive?.id;
    if (associationId != null && associationId != _dernierAssociationIdChargee) {
      _dernierAssociationIdChargee = associationId;
      // Recharger réunions et caisses pour la nouvelle association active
      // à chaque basculement (§2.2.2). On diffère ces appels après la fin
      // du build en cours : ecouterX() déclenche notifyListeners() dès
      // qu'un premier résultat arrive, et l'appeler pendant
      // didChangeDependencies (qui fait partie de la phase de build) casse
      // Flutter avec "setState() or markNeedsBuild() called during build".
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<MeetingViewModel>().ecouterReunions(associationId);
        context.read<CaisseViewModel>().ecouterCaisses(associationId);
        context.read<LoanViewModel>().ecouterPrets(associationId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final association = context.watch<AssociationViewModel>().associationActive;
    final meetingVm = context.watch<MeetingViewModel>();
    final caisseVm = context.watch<CaisseViewModel>();

    if (association == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final prochaineReunion = meetingVm.reunions
        .where((r) => r.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(association.nom),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<MeetingViewModel>().ecouterReunions(association.id);
          context.read<CaisseViewModel>().ecouterCaisses(association.id);
          context.read<LoanViewModel>().ecouterPrets(association.id);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Statistiques', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Membres', value: '${association.nombreMembres}', icon: Icons.people)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Réunions', value: '${meetingVm.reunions.length}', icon: Icons.event)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Caisses', value: '${caisseVm.caisses.length}', icon: Icons.account_balance_wallet)),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Solde total',
                    value: '${_formatFcfa.format(caisseVm.soldeTotal)} FCFA',
                    icon: Icons.savings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (prochaineReunion.isNotEmpty) ...[
              Text('Prochaine réunion', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text(prochaineReunion.first.titre),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy').format(prochaineReunion.first.date)} à ${prochaineReunion.first.heure}',
                  ),
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.meetingDetail, arguments: prochaineReunion.first.id),
                    child: const Text('Voir détails'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text('Mes Caisses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...caisseVm.caisses.map(
              (c) => Card(
                child: ListTile(
                  title: Text(c.nom),
                  trailing: Text('${_formatFcfa.format(c.solde)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.caisseDetail, arguments: c.id),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: _DashboardActionsMenu(associationId: association.id),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Boutons d'action rapide du tableau de bord : +Réunion, +Caisse, +Membre
/// (wireframe §7.1.2).
class _DashboardActionsMenu extends StatelessWidget {
  final String associationId;

  const _DashboardActionsMenu({required this.associationId});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add),
      onSelected: (value) {
        switch (value) {
          case 'reunion':
            Navigator.of(context).pushNamed(AppRoutes.meetingForm);
            break;
          case 'caisse':
            Navigator.of(context).pushNamed(AppRoutes.finances);
            break;
          case 'membre':
            Navigator.of(context).pushNamed(AppRoutes.members);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'reunion', child: Text('+ Réunion')),
        PopupMenuItem(value: 'caisse', child: Text('+ Caisse')),
        PopupMenuItem(value: 'membre', child: Text('+ Membre')),
      ],
    );
  }
}