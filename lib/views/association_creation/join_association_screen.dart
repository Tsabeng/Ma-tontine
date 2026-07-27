import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../config/routes.dart';

/// Écran "Rejoindre une association" — fidèle au wireframe §7.1.4.
class JoinAssociationScreen extends StatefulWidget {
  const JoinAssociationScreen({super.key});

  @override
  State<JoinAssociationScreen> createState() => _JoinAssociationScreenState();
}

class _JoinAssociationScreenState extends State<JoinAssociationScreen> {
  final _codeController = TextEditingController();

  Future<void> _rejoindre() async {
    final uid = context.read<AuthViewModel>().currentUser?.uid;
    if (uid == null || _codeController.text.trim().isEmpty) return;

    final association = await context.read<AssociationViewModel>().rejoindreParCode(
          uid: uid,
          code: _codeController.text.trim(),
        );

    if (association != null && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssociationViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rejoindre une Association')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Entrez le code d\'invitation'),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: 'ABCD-EFGH'),
            ),
            const SizedBox(height: 24),
            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: vm.isLoading ? null : _rejoindre,
              child: vm.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Rejoindre l'association"),
            ),
          ],
        ),
      ),
    );
  }
}
