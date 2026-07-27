import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Gère les notifications push (FCM) et locales.
/// Référence : §3.4.3 — notifications spécifiques à l'association active.
///
/// NOTE: L'envoi effectif de notifications push à d'autres utilisateurs
/// (ex : "notifier l'administrateur", "rappel 24h avant") nécessite une
/// Cloud Function côté serveur (déclenchée par un trigger Firestore ou
/// un scheduler). Ce service gère la partie client : récupération du
/// token, permissions, et affichage des notifications locales/entrantes.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialiser() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    FirebaseMessaging.onMessage.listen(_afficherNotificationLocale);
  }

  Future<String?> getToken() => _messaging.getToken();

  /// Abonne l'appareil aux notifications d'une association donnée, afin
  /// de ne recevoir que les notifications pertinentes pour l'association
  /// active (§3.4.3).
  Future<void> sAbonnerAssociation(String associationId) {
    return _messaging.subscribeToTopic('association_$associationId');
  }

  Future<void> seDesabonnerAssociation(String associationId) {
    return _messaging.unsubscribeFromTopic('association_$associationId');
  }

  void _afficherNotificationLocale(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'ma_tontine_default',
      'Ma Tontine — Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }
}
