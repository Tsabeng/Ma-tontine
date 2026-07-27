import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/association_viewmodel.dart';
import '../../config/routes.dart';

class AssociationCreationScreen extends StatefulWidget {
  const AssociationCreationScreen({super.key});

  @override
  State<AssociationCreationScreen> createState() => _AssociationCreationScreenState();
}

class _AssociationCreationScreenState extends State<AssociationCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _paysController = TextEditingController();
  final _villeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();

  Future<void> _creer() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = context.read<AuthViewModel>().currentUser?.uid;
    if (uid == null) return;

    final association = await context.read<AssociationViewModel>().creerAssociation(
          uid: uid,
          nom: _nomController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          pays: _paysController.text.trim().isEmpty ? null : _paysController.text.trim(),
          ville: _villeController.text.trim().isEmpty ? null : _villeController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          telephone: _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
        );

    if (association != null && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssociationViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Créer une association')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: "Nom de l'association *"),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _paysController,
                      decoration: const InputDecoration(labelText: 'Pays'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _villeController,
                      decoration: const InputDecoration(labelText: 'Ville'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email de contact'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: 'Téléphone de contact'),
              ),
              const SizedBox(height: 24),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: vm.isLoading ? null : _creer,
                child: vm.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Créer l'association"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
