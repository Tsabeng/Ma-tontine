import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Gère l'inscription, la connexion et la session utilisateur.
/// Référence : §3.1 Module Authentification.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Inscription par email / mot de passe — §3.1.1
  Future<UserModel> inscription({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String motDePasse,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: motDePasse,
    );

    final uid = credential.user!.uid;

    // Force le rafraîchissement du jeton d'authentification avant la
    // première écriture Firestore. Sans cela, la requête Firestore peut
    // partir avec un jeton pas encore à jour juste après la création du
    // compte, ce qui provoque une erreur permission-denied alors que les
    // règles de sécurité sont pourtant correctes.
    await credential.user!.getIdToken(true);

    final newUser = UserModel(
      uid: uid,
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
      createdAt: DateTime.now(),
      associations: const [],
    );

    await _firestore.collection('users').doc(uid).set(newUser.toMap());
    return newUser;
  }

  /// Connexion par email / mot de passe — §3.1.2
  Future<UserModel> connexion({
    required String email,
    required String motDePasse,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: motDePasse,
    );
    return getUserProfile(credential.user!.uid);
  }

  /// Connexion via Google (optionnelle) — §3.1.2
  Future<UserModel?> connexionGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // annulé par l'utilisateur

    final googleAuth = await googleUser.authentication;
    final oauthCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);
    final uid = userCredential.user!.uid;
    await userCredential.user!.getIdToken(true);

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      // Première connexion via Google : on crée le profil.
      final nameParts = (userCredential.user!.displayName ?? '').split(' ');
      final newUser = UserModel(
        uid: uid,
        prenom: nameParts.isNotEmpty ? nameParts.first : '',
        nom: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        email: userCredential.user!.email ?? '',
        telephone: userCredential.user!.phoneNumber ?? '',
        photoURL: userCredential.user!.photoURL,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      return newUser;
    }
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel> watchUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromFirestore(doc));
  }

  Future<void> deconnexion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> reinitialiserMotDePasse(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}