# Ma Tontine — Guide d'installation

## 1. Prérequis
- Flutter SDK installé (`flutter --version` doit fonctionner)
- Un compte Firebase (https://console.firebase.google.com)
- Node.js (pour la CLI Firebase) et Dart activé pour FlutterFire

## 2. Récupérer le squelette généré
Dézippe `ma_tontine.zip` où tu veux développer, par exemple :
```
unzip ma_tontine.zip -d ~/dev/
cd ~/dev/ma_tontine
```

## 3. Générer les dossiers de plateforme (android/ios/web)
Le sandbox où le code a été écrit n'a pas le SDK Flutter installé, donc
les dossiers `android/`, `ios/`, `web/` ne sont PAS inclus. Génère-les
sur ta machine, dans le dossier du projet :
```
flutter create --project-name ma_tontine .
```
⚠️ Cette commande ne touchera pas ton dossier `lib/` ni ton
`pubspec.yaml` s'ils existent déjà (elle complète, ne remplace pas).

## 4. Installer les dépendances
```
flutter pub get
```

## 5. Configurer Firebase
1. Crée un projet sur https://console.firebase.google.com
2. Installe la CLI Firebase si besoin : `npm install -g firebase-tools`
3. Installe FlutterFire CLI : `dart pub global activate flutterfire_cli`
4. Depuis le dossier du projet :
   ```
   firebase login
   flutterfire configure
   ```
   Cela génère automatiquement `lib/firebase_options.dart` et configure
   android/ios pour toi.
5. Dans `lib/main.dart`, remplace :
   ```dart
   await Firebase.initializeApp();
   ```
   par :
   ```dart
   import 'firebase_options.dart';
   ...
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```

## 6. Activer les services Firebase nécessaires
Dans la console Firebase :
- **Authentication** → activer Email/Password et Google
- **Firestore Database** → créer la base (mode production)
- **Storage** → activer (pour logos/photos)
- **Cloud Messaging** → déjà actif par défaut

## 7. Déployer les règles de sécurité Firestore
Les règles sont décrites au §4.3.1 du cahier des charges. Crée un
fichier `firestore.rules` à la racine avec ces règles (à adapter/étendre
pour `caisses`, `transactions`, `loans` selon le même principe), puis :
```
firebase deploy --only firestore:rules
```

## 8. Lancer l'application
```
flutter run
```
