import 'package:intl/intl.dart';

/// Fonctions utilitaires réutilisées à travers les écrans.
class AppHelpers {
  static final _formatMontant = NumberFormat.decimalPattern('fr_FR');

  static String formaterMontant(double montant, {String devise = 'FCFA'}) {
    return '${_formatMontant.format(montant)} $devise';
  }

  static String formaterDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formaterDateHeure(DateTime date, String heure) {
    return '${formaterDate(date)} à $heure';
  }

  static bool emailValide(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  static bool motDePasseValide(String motDePasse) {
    return motDePasse.length >= 8;
  }

  /// Normalise un code d'invitation saisi par l'utilisateur (majuscules,
  /// tiret conservé) — cohérent avec AssociationService._genererCodeInvitation.
  static String normaliserCodeInvitation(String code) {
    return code.trim().toUpperCase();
  }
}
