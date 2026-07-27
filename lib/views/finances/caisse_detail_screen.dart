import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/caisse_viewmodel.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/caisse_model.dart';
import '../../models/transaction_model.dart';
import '../../services/pdf_service.dart';

final _formatFcfa = NumberFormat.decimalPattern('fr_FR');

/// Détail d'une caisse : solde en temps réel, opérations (cotisation /
/// décaissement), historique des transactions, export PDF/CSV.
/// Référence : §3.5.3. L'ID de la caisse est transmis via les arguments
/// de route (`Navigator.pushNamed(..., arguments: caisseId)`).
class CaisseDetailScreen extends StatelessWidget {
  const CaisseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caisseId = ModalRoute.of(context)!.settings.arguments as String;
    final vm = context.watch<CaisseViewModel>();
    final caisse = vm.caisses.where((c) => c.id == caisseId).isNotEmpty
        ? vm.caisses.firstWhere((c) => c.id == caisseId)
        : null;

    if (caisse == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(caisse.nom),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            onSelected: (format) => _exporter(context, caisse, format),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'pdf', child: Text('Exporter en PDF')),
              PopupMenuItem(value: 'csv', child: Text('Exporter en CSV')),
            ],
          ),
        ],
      ),
      body: Column(
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
                Text(caisse.type.label, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  '${_formatFcfa.format(caisse.solde)} FCFA',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                if (caisse.objectif != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (caisse.solde / caisse.objectif!).clamp(0, 1),
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Objectif : ${_formatFcfa.format(caisse.objectif)} FCFA',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Cotisation'),
                    onPressed: () => _afficherFormulaireOperation(context, caisse, entree: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.remove),
                    label: const Text('Décaissement'),
                    onPressed: () => _afficherFormulaireOperation(context, caisse, entree: false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Historique', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: vm.transactionsDe(caisse.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final transactions = snapshot.data!;
                if (transactions.isEmpty) return const Center(child: Text('Aucune transaction pour le moment'));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    final estEntree = t.type.estEntree;
                    return ListTile(
                      leading: Icon(
                        estEntree ? Icons.arrow_downward : Icons.arrow_upward,
                        color: estEntree ? Colors.green : Colors.red,
                      ),
                      title: Text(_labelType(t.type)),
                      subtitle: Text('${DateFormat('dd/MM/yyyy').format(t.date)} · Réf. ${t.reference}'),
                      trailing: Text(
                        '${estEntree ? '+' : '-'}${_formatFcfa.format(t.montant)} FCFA',
                        style: TextStyle(
                          color: estEntree ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _labelType(TypeTransaction type) {
    switch (type) {
      case TypeTransaction.cotisation:
        return 'Cotisation';
      case TypeTransaction.decaissement:
        return 'Décaissement';
      case TypeTransaction.depot:
        return 'Dépôt';
      case TypeTransaction.retrait:
        return 'Retrait';
      case TypeTransaction.remboursement:
        return 'Remboursement';
    }
  }

  void _afficherFormulaireOperation(BuildContext context, CaisseModel caisse, {required bool entree}) {
    final montantController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(entree ? 'Ajouter une cotisation' : 'Effectuer un décaissement',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optionnel)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final association = ctx.read<AssociationViewModel>().associationActive;
                final uid = ctx.read<AuthViewModel>().currentUser?.uid;
                final montant = double.tryParse(montantController.text);
                if (association == null || uid == null || montant == null) return;

                final vm = ctx.read<CaisseViewModel>();
                if (entree) {
                  await vm.ajouterCotisation(
                    associationId: association.id,
                    caisseId: caisse.id,
                    membreId: uid,
                    montant: montant,
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  );
                } else {
                  await vm.effectuerDecaissement(
                    associationId: association.id,
                    caisseId: caisse.id,
                    membreId: uid,
                    montant: montant,
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  );
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exporter(BuildContext context, CaisseModel caisse, String format) async {
    final transactions = await context.read<CaisseViewModel>().transactionsDe(caisse.id).first;
    final file = format == 'pdf'
        ? await PdfService().exporterTransactionsPdf(caisse.nom, transactions)
        : await PdfService().exporterTransactionsCsv(caisse.nom, transactions);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export généré : ${file.path}')),
      );
    }
  }
}
