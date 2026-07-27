import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/app_theme.dart';
import 'config/routes.dart';

import 'services/auth_service.dart';
import 'services/association_service.dart';
import 'services/meeting_service.dart';
import 'services/caisse_service.dart';
import 'services/loan_service.dart';
import 'services/member_service.dart';
import 'services/notification_service.dart';

import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/association_viewmodel.dart';
import 'viewmodels/meeting_viewmodel.dart';
import 'viewmodels/caisse_viewmodel.dart';
import 'viewmodels/loan_viewmodel.dart';
import 'viewmodels/member_viewmodel.dart';

import 'views/onboarding/onboarding_screen.dart';
import 'views/association_selection/association_selection_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: `firebase_options.dart` est généré par la CLI FlutterFire
  // (`flutterfire configure`) et n'est pas inclus ici — voir le README
  // pour la procédure de configuration Firebase.
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);


  await initializeDateFormatting('fr_FR', null);

  runApp(const MaTontineApp());
}

class MaTontineApp extends StatelessWidget {
  const MaTontineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services — instanciés une seule fois, injectés dans les ViewModels.
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => AssociationService()),
        Provider(create: (_) => MeetingService()),
        Provider(create: (_) => CaisseService()),
        Provider(create: (_) => LoanService()),
        Provider(create: (_) => MemberService()),
        Provider(create: (_) => NotificationService()),

        // ViewModels — exposés à tout l'arbre de widgets.
        ChangeNotifierProvider(create: (ctx) => AuthViewModel(ctx.read<AuthService>())),
        ChangeNotifierProvider(create: (ctx) => AssociationViewModel(ctx.read<AssociationService>())),
        ChangeNotifierProvider(create: (ctx) => MeetingViewModel(ctx.read<MeetingService>())),
        ChangeNotifierProvider(create: (ctx) => CaisseViewModel(ctx.read<CaisseService>())),
        ChangeNotifierProvider(create: (ctx) => LoanViewModel(ctx.read<LoanService>())),
        ChangeNotifierProvider(create: (ctx) => MemberViewModel(ctx.read<MemberService>())),
      ],
      child: MaterialApp(
        title: 'Ma Tontine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routes: AppRoutes.routes,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Point d'entrée conditionnel du flux §2.2.1 : redirige vers
/// l'onboarding, l'authentification, ou directement l'écran de
/// sélection d'association selon l'état de connexion.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    switch (auth.status) {
      case AuthStatus.inconnu:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.nonAuthentifie:
        return const OnboardingScreen();
      case AuthStatus.authentifie:
        return const AssociationSelectionScreen();
    }
  }
}