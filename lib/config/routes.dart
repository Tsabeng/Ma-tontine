import 'package:flutter/material.dart';

import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/onboarding/onboarding_screen.dart';
import '../views/association_selection/association_selection_screen.dart';
import '../views/association_creation/association_creation_screen.dart';
import '../views/association_creation/join_association_screen.dart';
import '../views/home/home_screen.dart';
import '../views/meetings/meetings_list_screen.dart';
import '../views/meetings/meeting_detail_screen.dart';
import '../views/meetings/meeting_form_screen.dart';
import '../views/finances/finances_screen.dart';
import '../views/finances/caisse_detail_screen.dart';
import '../views/finances/mon_bilan_screen.dart';
import '../views/finances/loans_screen.dart';
import '../views/members/members_list_screen.dart';

/// Table de routes centralisée — suit le flux décrit en §2.2 :
/// Ouverture -> Auth -> Sélection association -> Tableau de bord.
class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const associationSelection = '/associations';
  static const associationCreation = '/associations/creer';
  static const joinAssociation = '/associations/rejoindre';
  static const home = '/home';
  static const meetings = '/reunions';
  static const meetingDetail = '/reunions/detail';
  static const meetingForm = '/reunions/nouvelle';
  static const finances = '/finances';
  static const caisseDetail = '/finances/caisse';
  static const monBilan = '/finances/bilan';
  static const loans = '/finances/prets';
  static const members = '/membres';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (_) => const OnboardingScreen(),
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        associationSelection: (_) => const AssociationSelectionScreen(),
        associationCreation: (_) => const AssociationCreationScreen(),
        joinAssociation: (_) => const JoinAssociationScreen(),
        home: (_) => const HomeScreen(),
        meetings: (_) => const MeetingsListScreen(),
        meetingDetail: (_) => const MeetingDetailScreen(),
        meetingForm: (_) => const MeetingFormScreen(),
        finances: (_) => const FinancesScreen(),
        caisseDetail: (_) => const CaisseDetailScreen(),
        monBilan: (_) => const MonBilanScreen(),
        loans: (_) => const LoansScreen(),
        members: (_) => const MembersListScreen(),
      };
}
