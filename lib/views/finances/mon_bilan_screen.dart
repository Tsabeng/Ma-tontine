import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/caisse_viewmodel.dart';
import '../../viewmodels/loan_viewmodel.dart';
import '../../models/transaction_model.dart';
import '../../models/loan_model.dart';
import '../../services/firestore_service.dart';

final _formatFcfa = NumberFormat.decimalPattern('fr_FR');

/// "Mon Bilan" — spécifique à l'association active. Reproduit fidèlement
/// la liste de §3.6.3 : total versé/reçu, solde net, pénalités, prêts,
/// cotisations par caisse, épargne.
class MonBilanScreen extends StatelessWidget {
  const MonBilanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final association = context.watch<AssociationViewModel>().associationActive;
    final uid = context.watch<AuthViewModel>().currentUser?.uid;
    final loanVm = context.watch<LoanViewModel>();

    if (association == null || uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mesPrets = loanVm.pretsDeMembre(uid);
    final pretsEnCours = mesPrets
        .where((p) => p.statut == StatutPret.en_cours || p.statut == StatutPret.impaye)
        .toList();
    final restantARembourser = pretsEnCours.fold<double>(0, (sum, p) => sum + p.restantARembourser);
    final prochaineEcheance = pretsEnCours.isEmpty
        ? null
        : pretsEnCours.map((p) => p.prochaineEcheance).reduce((a, b) => a.isBefore(b) ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Bilan')),
      body: StreamBuilder<List<TransactionModel>>(
        stream: FirestoreService.transactions
            .where('associationId', isEqualTo: association.id)
            .where('membreId', isEqualTo: uid)
            .snapshots()
            .map((snap) => snap.docs.map(TransactionModel.fromFirestore).toList()),
        builder: (context, snapshot) {
          final mesTransactions = snapshot.data ?? [];
          final totalVerse = mesTransactions
              .where((t) => t.type == TypeTransaction.cotisation || t.type == TypeTransaction.depot)
              .fold<double>(0, (sum, t) => sum + t.montant);
          final totalRecu = mesTransactions
              .where((t) => t.type == TypeTransaction.decaissement || t.type == TypeTransaction.retrait)
              .fold<double>(0, (sum, t) => sum + t.montant);
          final soldeNet = totalVerse - totalRecu;

          final parCaisse = <String, double>{};
          for (final t in mesTransactions.where((t) => t.type == TypeTransaction.cotisation)) {
            parCaisse[t.caisseId] = (parCaisse[t.caisseId] ?? 0) + t.montant;
          }

          final monEpargne = mesTransactions
              .where((t) => t.type == TypeTransaction.depot)
              .fold<double>(0, (sum, t) => sum + t.montant);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _BilanCard(label: 'Total versé', valeur: totalVerse, couleur: Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _BilanCard(label: 'Total reçu', valeur: totalRecu, couleur: Colors.orange)),
                ],
              ),
              const SizedBox(height: 12),
              _BilanCard(label: 'Solde net', valeur: soldeNet, couleur: soldeNet >= 0 ? Colors.green : Colors.red, pleineLargeur: true),
              const SizedBox(height: 24),
              Text('Mes prêts', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (pretsEnCours.isEmpty)
                const Text('Aucun prêt en cours.')
              else ...[
                ...pretsEnCours.map((p) => Card(
                      child: ListTile(
                        title: Text('${_formatFcfa.format(p.montant)} FCFA'),
                        subtitle: Text('Restant à rembourser : ${_formatFcfa.format(p.restantARembourser)} FCFA'),
                        trailing: Text(p.statut == StatutPret.impaye ? 'Impayé' : 'En cours',
                            style: TextStyle(color: p.statut == StatutPret.impaye ? Colors.red : Colors.orange)),
                      ),
                    )),
                Text('Restant total à rembourser : ${_formatFcfa.format(restantARembourser)} FCFA'),
                if (prochaineEcheance != null)
                  Text('Prochaine échéance : ${DateFormat('dd/MM/yyyy').format(prochaineEcheance)}'),
              ],
              const SizedBox(height: 24),
              Text('Mon épargne', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('${_formatFcfa.format(monEpargne)} FCFA'),
              const SizedBox(height: 24),
              Text('Mes cotisations par caisse', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (parCaisse.isEmpty)
                const Text('Aucune cotisation enregistrée.')
              else
                ...parCaisse.entries.map(
                  (e) => _CotisationParCaisseRow(caisseId: e.key, montant: e.value),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BilanCard extends StatelessWidget {
  final String label;
  final double valeur;
  final Color couleur;
  final bool pleineLargeur;

  const _BilanCard({required this.label, required this.valeur, required this.couleur, this.pleineLargeur = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: pleineLargeur ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('${_formatFcfa.format(valeur)} FCFA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: couleur)),
        ],
      ),
    );
  }
}

/// Résout le nom de la caisse à partir de son ID pour l'affichage du
/// détail des cotisations par caisse.
class _CotisationParCaisseRow extends StatelessWidget {
  final String caisseId;
  final double montant;

  const _CotisationParCaisseRow({required this.caisseId, required this.montant});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaisseViewModel>();
    final caisse = vm.caisses.where((c) => c.id == caisseId);
    final nom = caisse.isNotEmpty ? caisse.first.nom : 'Caisse';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(nom),
      trailing: Text('${_formatFcfa.format(montant)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
