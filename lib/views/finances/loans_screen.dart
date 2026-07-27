import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/loan_viewmodel.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/loan_model.dart';
import '../../models/user_model.dart';

final _formatFcfa = NumberFormat.decimalPattern('fr_FR');

/// Écran Prêts — demande par un membre, validation par l'administrateur,
/// suivi des remboursements. Référence : §3.6.2.
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loanVm = context.watch<LoanViewModel>();
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;
    final association = context.watch<AssociationViewModel>().associationActive;

    final estAdmin = user != null &&
        association != null &&
        user.associations.any((a) => a.associationId == association.id && a.role == MembreRole.admin);

    return DefaultTabController(
      length: estAdmin ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prêts'),
          bottom: estAdmin
              ? TabBar(
                  tabs: [
                    Tab(text: 'En attente (${loanVm.pretsEnAttente.length})'),
                    const Tab(text: 'Tous les prêts'),
                  ],
                )
              : null,
        ),
        body: loanVm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : estAdmin
                ? TabBarView(
                    children: [
                      _ListePrets(prets: loanVm.pretsEnAttente, estAdmin: true, afficherActionsValidation: true),
                      _ListePrets(prets: loanVm.prets, estAdmin: true, afficherActionsValidation: false),
                    ],
                  )
                : _ListePrets(
                    prets: user != null ? loanVm.pretsDeMembre(user.uid) : [],
                    estAdmin: false,
                    afficherActionsValidation: false,
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _afficherFormulaireDemande(context),
          icon: const Icon(Icons.request_page_outlined),
          label: const Text('Demander un prêt'),
        ),
      ),
    );
  }

  void _afficherFormulaireDemande(BuildContext context) {
    final montantController = TextEditingController();
    final tauxController = TextEditingController(text: '5');
    final dureeController = TextEditingController(text: '3');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Demande de prêt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant demandé (FCFA)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tauxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Taux d'intérêt (%)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dureeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Durée (en mois)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final association = ctx.read<AssociationViewModel>().associationActive;
                final uid = ctx.read<AuthViewModel>().currentUser?.uid;
                final montant = double.tryParse(montantController.text);
                final taux = double.tryParse(tauxController.text);
                final duree = int.tryParse(dureeController.text);
                if (association == null || uid == null || montant == null || taux == null || duree == null) return;

                await ctx.read<LoanViewModel>().demanderPret(
                      associationId: association.id,
                      membreId: uid,
                      montant: montant,
                      tauxInteret: taux,
                      dureeEnMois: duree,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Envoyer la demande'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListePrets extends StatelessWidget {
  final List<LoanModel> prets;
  final bool estAdmin;
  final bool afficherActionsValidation;

  const _ListePrets({required this.prets, required this.estAdmin, required this.afficherActionsValidation});

  @override
  Widget build(BuildContext context) {
    if (prets.isEmpty) {
      return const Center(child: Text('Aucun prêt à afficher'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prets.length,
      itemBuilder: (context, index) {
        final p = prets[index];
        return Card(
          child: ListTile(
            title: Text('${_formatFcfa.format(p.montant)} FCFA · ${p.tauxInteret.toStringAsFixed(0)}%'),
            subtitle: Text(
              '${p.duree} mois · Restant : ${_formatFcfa.format(p.restantARembourser)} FCFA\n'
              'Échéance : ${DateFormat('dd/MM/yyyy').format(p.prochaineEcheance)}',
            ),
            isThreeLine: true,
            trailing: afficherActionsValidation
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Valider',
                        onPressed: () => context.read<LoanViewModel>().validerPret(p.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Refuser',
                        onPressed: () => context.read<LoanViewModel>().refuserPret(p.id),
                      ),
                    ],
                  )
                : _StatutChip(statut: p.statut),
            onTap: !afficherActionsValidation && p.statut != StatutPret.solde
                ? () => _afficherFormulaireRemboursement(context, p)
                : null,
          ),
        );
      },
    );
  }

  void _afficherFormulaireRemboursement(BuildContext context, LoanModel loan) {
    final montantController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enregistrer un remboursement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Restant à rembourser : ${_formatFcfa.format(loan.restantARembourser)} FCFA'),
            const SizedBox(height: 16),
            TextField(
              controller: montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant remboursé (FCFA)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final montant = double.tryParse(montantController.text);
                if (montant == null) return;
                await ctx.read<LoanViewModel>().enregistrerRemboursement(loan.id, montant);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Valider le remboursement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatutChip extends StatelessWidget {
  final StatutPret statut;

  const _StatutChip({required this.statut});

  Color get _couleur {
    switch (statut) {
      case StatutPret.en_attente:
        return Colors.blueGrey;
      case StatutPret.en_cours:
        return Colors.orange;
      case StatutPret.solde:
        return Colors.green;
      case StatutPret.impaye:
        return Colors.red;
      case StatutPret.refuse:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(statut.label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: _couleur,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
