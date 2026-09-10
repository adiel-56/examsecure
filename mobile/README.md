# ExamSecure — Application mobile Flutter

Application mobile (Android/iOS) de vente et consultation sécurisée d'épreuves
universitaires. Backend Django REST séparé dans `/backend`.

## Prérequis

- Flutter 3.47.1 (stable), Dart 3.13.1 — voir `environment` dans `pubspec.yaml`
- Un backend Django lancé (voir `/backend/README.md`)

## Démarrage

```bash
flutter pub get
flutter run
```

## Configuration de l'URL de l'API

Centralisée dans `lib/core/constants/api_constants.dart`.
Ne jamais utiliser `localhost` pour tester sur un téléphone physique —
utiliser l'IP locale de votre machine de développement.

## Architecture

Voir `lib/` : `core/`, `models/`, `services/`, `repositories/`, `providers/`,
`features/{auth,student,admin}/`, `widgets/`.

Flux logique : `UI → Provider → Repository → Service → API Django`.
