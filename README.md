# ExamSecure — Vente et consultation sécurisée d'épreuves universitaires

Ce dépôt contient les deux parties du projet, conformément au cahier des
charges (prompt maître) :

```
examsecure/
├── backend/   Django REST Framework + MySQL + JWT + KkiaPay
└── mobile/    Application Flutter (Android/iOS) — étudiant + admin
```

## État de ce livrable

Ceci est une **implémentation initiale complète de l'architecture** (Phase 0
finalisée + une bonne partie des Phases 1 à 12 amorcées) : tous les modèles,
endpoints, écrans et flux décrits dans le cahier des charges sont en place
et suivent scrupuleusement l'architecture demandée (`core/ → services/ →
repositories/ → providers/ → features/` côté Flutter ; `apps/<domaine>`
côté Django). Avant mise en production, il reste à :

1. **Exécuter réellement le pipeline de vérification** — impossible dans
   cet environnement (pas de Flutter SDK ni d'accès à pub.dev ici) :
   ```bash
   cd mobile
   flutter pub get
   flutter analyze
   flutter test
   flutter run
   ```
2. **Générer les dossiers natifs Android/iOS** avec `flutter create .`
   dans `mobile/` (fait avec votre Flutter 3.47.1 stable local — ne pas
   laisser un outil générer ces fichiers avec une autre version).
3. **Créer la base MySQL** et exécuter les migrations Django :
   ```bash
   cd backend
   python -m venv .venv && source .venv/Scripts/activate
   pip install -r requirements/dev.txt
   cp .env.example .env   # puis renseigner les vraies valeurs
   python manage.py makemigrations
   python manage.py migrate
   python manage.py createsuperuser
   python manage.py runserver
   ```
4. **Brancher un vrai lecteur PDF** dans
   `mobile/lib/features/student/reader/secure_reader_screen.dart` (le
   pipeline sécurisé token → téléchargement → chiffrement AES →
   déchiffrement est déjà fonctionnel ; il ne manque que le rendu visuel
   page-par-page, à faire avec un package validé explicitement pour
   Flutter 3.47.1/Dart 3.13.1 — voir la note dans ce fichier).
5. **Brancher le SDK/widget KkiaPay réel** dans
   `mobile/lib/features/student/exam_details/exam_details_screen.dart`
   (actuellement un point d'intégration clairement marqué ; le flux
   serveur — initiate/verify/idempotence — est déjà implémenté et testé
   côté Django).
6. Ajouter un sélecteur de fichier (pour l'import PDF admin) une fois un
   package validé.

## Sécurité déjà en place

- Rôle STUDENT/ADMIN toujours revérifié côté Django (jamais fait confiance
  à ce qu'envoie Flutter).
- Fichiers d'épreuves stockés hors de toute URL publique
  (`apps/exams/storage.py`), accès uniquement via un `DownloadToken`
  à usage unique et durée de vie limitée (`apps/downloads`).
- Idempotence des paiements KkiaPay garantie par contrainte d'unicité +
  vérification explicite (`apps/payments/views.py::PaymentVerifyView`),
  avec un test dédié (`apps/payments/tests/test_idempotence.py`).
- Tokens JWT stockés côté Flutter uniquement via `flutter_secure_storage`
  (Android Keystore / iOS Keychain), jamais en clair.
- Clé de chiffrement AES locale générée aléatoirement et stockée de la
  même façon — jamais hardcodée (`core/security/local_encryption_service.dart`).
- Audit log des actions sensibles (paiements, déblocages, CRUD admin,
  suspensions de compte).
- Messages d'erreur génériques envoyés au client (jamais de détail
  technique — `apps/core_utils/exceptions.py` côté Django,
  `core/errors/app_exception.dart` côté Flutter).

## Vérification effectuée dans cet environnement

- Tous les fichiers Python du backend compilent (`python3 -m py_compile`,
  sans erreur de syntaxe).
- Tous les fichiers Dart ont des accolades/parenthèses/crochets équilibrés
  (vérification statique basique ; ne remplace pas `flutter analyze`).

Voir `backend/README` (section ci-dessus) et `mobile/README.md` pour le
détail de mise en route de chaque partie.
