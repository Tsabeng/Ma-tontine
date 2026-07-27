import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { inconnu, nonAuthentifie, authentifie }

/// Expose l'état d'authentification et le profil utilisateur courant
/// à toute l'application. Référence : §3.1.
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel(this._authService) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  AuthStatus status = AuthStatus.inconnu;
  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      status = AuthStatus.nonAuthentifie;
      currentUser = null;
    } else {
      currentUser = await _authService.getUserProfile(firebaseUser.uid);
      status = AuthStatus.authentifie;
    }
    notifyListeners();
  }

  Future<bool> inscription({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String motDePasse,
  }) async {
    return _run(() async {
      currentUser = await _authService.inscription(
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        motDePasse: motDePasse,
      );
    });
  }

  Future<bool> connexion({required String email, required String motDePasse}) async {
    return _run(() async {
      currentUser = await _authService.connexion(email: email, motDePasse: motDePasse);
    });
  }

  Future<bool> connexionGoogle() async {
    return _run(() async {
      final user = await _authService.connexionGoogle();
      if (user != null) currentUser = user;
    });
  }

  Future<void> deconnexion() async {
    await _authService.deconnexion();
    currentUser = null;
    status = AuthStatus.nonAuthentifie;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
