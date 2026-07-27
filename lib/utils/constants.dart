/// Constantes partagées à travers l'application.
class AppConstants {
  static const String appName = 'Ma Tontine';
  static const String tagline = 'Simplifier, Sécuriser, Piloter votre association';

  static const int longueurMinMotDePasse = 8;
  static const int longueurCodeInvitation = 9; // format ABCD-EFGH (avec tiret)

  /// Délai avant rappel automatique d'une réunion — §3.4.3.
  static const Duration rappelReunion = Duration(hours: 24);

  static const List<String> devises = ['FCFA', 'EUR', 'USD'];
}
