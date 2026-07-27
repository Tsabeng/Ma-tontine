import 'package:flutter/material.dart';
import '../../models/association_model.dart';

/// Ligne d'association dans le menu latéral (Drawer) — §3.2.4 et
/// wireframe §7.1.3. Permet le basculement rapide entre associations
/// sans repasser par l'écran de sélection complet.
class AssociationSelectorDrawerItem extends StatelessWidget {
  final AssociationModel association;
  final bool estActive;
  final VoidCallback onTap;

  const AssociationSelectorDrawerItem({
    super.key,
    required this.association,
    required this.estActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: estActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.15),
        child: Text(
          association.nom.isNotEmpty ? association.nom[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 12,
            color: estActive ? Colors.white : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      title: Text(
        association.nom,
        style: TextStyle(fontWeight: estActive ? FontWeight.bold : FontWeight.normal),
      ),
      trailing: estActive ? Icon(Icons.check_circle, size: 18, color: Theme.of(context).colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
