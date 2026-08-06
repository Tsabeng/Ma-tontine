import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../viewmodels/caisse_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/caisse_model.dart';
import '../../config/routes.dart';

final _formatFcfa = NumberFormat.decimalPattern('fr_FR');

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  String? _associationIdChargee;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final associationId = context.watch<AssociationViewModel>().associationActive?.id;
    if (associationId != null && associationId != _associationIdChargee) {
      _associationIdChargee = associationId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CaisseViewModel>().ecouterCaisses(associationId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaisseViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.request_page_outlined),
            tooltip: 'Prêts',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.loans),
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart_outline),
            tooltip: 'Mon bilan',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.monBilan),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Solde total', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatFcfa.format(vm.soldeTotal)} FCFA',
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: vm.caisses.length,
                    itemBuilder: (context, index) {
                      final c = vm.caisses[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(_iconePourType(c.type))),
                          title: Text(c.nom),
                          subtitle: Text(c.type.label),
                          trailing: Text('${_formatFcfa.format(c.solde)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.caisseDetail, arguments: c.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _afficherFormulaireCaisse(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle caisse'),
      ),
    );
  }

  IconData _iconePourType(TypeCaisse type) {
    switch (type) {
      case TypeCaisse.solidarite:
        return Icons.volunteer_activism;
      case TypeCaisse.projets:
        return Icons.rocket_launch_outlined;
      case TypeCaisse.scolaire:
        return Icons.school_outlined;
      case TypeCaisse.epargne:
        return Icons.savings_outlined;
      case TypeCaisse.tontine:
        return Icons.autorenew;
      case TypeCaisse.personnalise:
        return Icons.account_balance_wallet_outlined;
    }
  }

  void _afficherFormulaireCaisse(BuildContext context) {
    final nomController = TextEditingController();
    final soldeController = TextEditingController();
    TypeCaisse typeSelectionne = TypeCaisse.solidarite;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nouvelle caisse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom de la caisse')),
              const SizedBox(height: 12),
              DropdownButtonFormField<TypeCaisse>(
                initialValue: typeSelectionne,
                decoration: const InputDecoration(labelText: 'Type'),
                items: TypeCaisse.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => typeSelectionne = v ?? typeSelectionne),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: soldeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Solde initial (optionnel)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final association = ctx.read<AssociationViewModel>().associationActive;
                  final uid = ctx.read<AuthViewModel>().currentUser?.uid;
                  if (association == null || uid == null || nomController.text.isEmpty) return;

                  await ctx.read<CaisseViewModel>().creerCaisse(
                        associationId: association.id,
                        nom: nomController.text.trim(),
                        type: typeSelectionne,
                        soldeInitial: double.tryParse(soldeController.text) ?? 0,
                        createdBy: uid,
                      );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}