# 📚 Architecture et Arborescence Détaillée du Projet ExamSecure

> **ExamSecure** est une plateforme complète (Backend Django REST + Application mobile Flutter) dédiée à la vente et à la consultation hautement sécurisée d'épreuves universitaires (examens, devoirs, corrigés, supports de cours).

---

## 📑 Table des Matières

1. [Vue d'Ensemble du Projet](#1-vue-densemble-du-projet)
2. [Arborescence Racine](#2-arborescence-racine)
3. [Architecture Détaillée du Backend (Django)](#3-architecture-détaillée-du-backend-django)
   - [Configuration Globale (`config/`)](#configuration-globale-config)
   - [Applications Métier (`apps/`)](#applications-métier-apps)
   - [Stockage Hermétique (`media_private/`)](#stockage-hermétique-media_private)
4. [Architecture Détaillée du Mobile (Flutter)](#4-architecture-détaillée-du-mobile-flutter)
   - [Socle Technique & Core (`lib/core/`)](#socle-technique--core-libcore)
   - [Données & Métier (`models/`, `repositories/`, `providers/`)](#données--métier)
   - [Interfaces Utilisateur (`features/`)](#interfaces-utilisateur-features)
   - [Composants Réutilisables (`widgets/`)](#composants-réutilisables-widgets)
5. [Flux de Sécurité et d'Échange de Données](#5-flux-de-sécurité-et-déchange-de-données)

---

## 1. Vue d'Ensemble du Projet

Le projet repose sur deux piliers strictement indépendants et découplés :

```
┌────────────────────────────────────────────────────────┐
│               MOBILE FLUTTER (Android / iOS)           │
│  - Espace Étudiant : Catalogue, KkiaPay, Lecteur AES   │
│  - Espace Administrateur : Dashboard, CRUD, Audit      │
└───────────────────────────┬────────────────────────────┘
                            │ HTTPS / REST (JSON + JWT)
                            ▼
┌────────────────────────────────────────────────────────┐
│               BACKEND DJANGO REST FRAMEWORK            │
│  - Base MySQL, Authentification & Autorisation stricte │
│  - Contrôle KkiaPay, Tokens Download, Audit Logs       │
│  - Fichiers PDF stockés hors de portée du Web public   │
└────────────────────────────────────────────────────────┘
```

---

## 2. Arborescence Racine

```
examsecure/
├── backend/                  # Serveur d'API Django REST Framework & base de données
├── mobile/                   # Application mobile Flutter (Android & iOS)
├── docs/                     # Maquettes interactives HTML et documentations de design
├── ARBORESCENCE.md           # Ce présent document d'architecture détaillé
└── README.md                 # Guide de démarrage rapide global
```

---

## 3. Architecture Détaillée du Backend (Django)

Le backend est structuré selon une architecture modulaire en applications Django isolées (`apps/`), garantissant une forte cohésion et un faible couplage.

```
backend/
├── manage.py                 # Point d'entrée des commandes d'administration Django
├── .env                      # Variables d'environnement locales (clés, DB, KkiaPay)
├── .env.example              # Exemple modèle des variables attendues
├── pytest.ini                # Configuration des tests unitaires et d'intégration
├── requirements/             # Gestion fine des dépendances Python
│   ├── base.txt              # Dépendances socles (Django, DRF, JWT, MySQL)
│   ├── dev.txt               # Outils de dev (pytest, flake8)
│   └── prod.txt              # Outils de production (gunicorn, sentry)
├── media_private/            # Fichiers PDF physiques isolés (jamais servis par URL directe)
│   ├── originals/            # PDF originaux uploadés par l'admin
│   └── secured/              # PDF sécurisés / traités (optionnel)
├── config/                   # Configuration du projet Django
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py           # Configuration commune (INSTALLED_APPS, JWT, REST_FRAMEWORK)
│   │   ├── dev.py            # Paramètres spécifiques de développement local
│   │   └── prod.py           # Paramètres durcis pour la mise en production
│   ├── asgi.py               # Interface serveur asynchrone (ASGI)
│   ├── wsgi.py               # Interface serveur synchrone standard (WSGI)
│   └── urls.py               # Routage racine des endpoints API (`/api/...`)
└── apps/                     # Modules applicatifs métier
    ├── core_utils/           # Utilitaires transverses & sécurité
    ├── accounts/             # Utilisateurs, Authentification & Rôles
    ├── filieres/             # Gestion des filières académiques
    ├── matieres/             # Gestion des matières par filière
    ├── exams/                # Gestion des épreuves (PDF, métadonnées, prix)
    ├── payments/             # Transactions & intégration KkiaPay
    ├── purchases/            # Droits d'accès et historique des achats
    ├── downloads/            # Téléchargement éphémère par jetons uniques
    ├── devices/              # Empreinte et restriction mono-appareil
    ├── unlock_requests/      # Déblocage de compte lors d'un changement d'appareil
    ├── notifications/        # Alertes système et in-app
    ├── statistics/           # Métriques et KPIs pour le dashboard administrateur
    └── audit/                # Journalisation immuable des événements sensibles
```

### Configuration Globale (`config/`)
- `base.py` : Paramètre l'authentification `rest_framework_simplejwt.authentication.JWTAuthentication`, configure la durée de vie des jetons (15 min access, 7 jours refresh), déclare le stockage privé `PRIVATE_MEDIA_ROOT` et active le gestionnaire d'exceptions global.
- `urls.py` : Déclare l'ensemble des routes sous le préfixe `/api/` : `/api/auth/`, `/api/exams/`, `/api/payments/`, `/api/admin/`, etc.

### Applications Métier (`apps/`)

#### 1. `apps.accounts` (Gestion des Comptes & Rôles)
- `models.py` : Modèle `User` héritant d'`AbstractUser`. Utilise l'e-mail comme identifiant de connexion (`USERNAME_FIELD = 'email'`), intègre le numéro de téléphone, la filière rattachée, et le rôle (`STUDENT` ou `ADMIN`).
- `serializers.py` : Sérialiseurs d'inscription, profil public, et `ExamSecureTokenObtainPairSerializer` qui injecte le profil et le rôle au moment du login.
- `views.py` : Endpoints d'inscription (`/api/auth/register/`), de connexion (`/api/auth/login/`), de rafraîchissement (`/api/auth/refresh/`) et de déconnexion (`/api/auth/logout/`).

#### 2. `apps.filieres` & `apps.matieres` (Catalogue Universitaire)
- Permettent la hiérarchie académique : **Filière** (ex. Génie Logiciel, Droit) ➡️ **Matières** (ex. Algorithmique, Droit Civil).
- Fournissent les endpoints de consultation pour les étudiants et de CRUD complet pour l'administrateur.

#### 3. `apps.exams` (Gestion des Épreuves & PDF)
- `models.py` : Modèle `Epreuve` comportant le titre, l'année académique, le prix en XOF, le nombre de pages, le type (Examen, TD, Corrigé, Cours), le statut (`DRAFT`, `PUBLISHED`, `ARCHIVED`), et le champ `fichier_original` pointant vers `private_storage`.
- `storage.py` : Classe de stockage personnalisée qui place les fichiers hors de la racine publique du serveur HTTP.
- `views.py` : Vue catalogue étudiant (filtre uniquement les épreuves publiées).
- `admin_views.py` : Vues d'administration réservées au rôle `ADMIN` pour créer (avec upload multipart du PDF), modifier, publier ou archiver les épreuves.

#### 4. `apps.payments` (Paiement KkiaPay & Idempotence)
- `kkiapay_client.py` : Client HTTP vérifiant directement auprès de l'API officielle KkiaPay l'état d'une transaction via sa référence.
- `views.py` :
  - `PaymentInitiateView` : Fournit au client la clé publique, le montant et le mode sandbox.
  - `PaymentVerifyView` : Point névralgique de sécurité. Reçoit la référence renvoyée par le widget KkiaPay, vérifie auprès de KkiaPay le montant, la devise et le statut `SUCCESS`, garantit l'idempotence (aucun doublon possible) et génère l'enregistrement d'accès `Achat` de façon transactionnelle (`atomic`).

#### 5. `apps.purchases` (Droits d'Accès)
- `models.py` : Modèle `Achat` liant un `User` (étudiant), une `Epreuve` et une `Transaction`. Contient le compteur de téléchargements et l'état (`VALIDE`, `BLOQUE`, `REVOQUE`).
- Endpoints permettant à l'étudiant de lister ses documents achetés et leurs états.

#### 6. `apps.downloads` (Téléchargement Éphémère & Sécurisé)
- `models.py` : Modèle `DownloadToken` générant des chaînes aléatoires sécurisées à durée de vie limitée (TTL 15 min), à usage unique (`used = True` dès consommation).
- `views.py` : `SecureFileDownloadView` valide le jeton, vérifie que l'appareil demandeur correspond à l'appareil actif de l'étudiant, consomme le jeton et renvoie le flux binaire via un `FileResponse`.

#### 7. `apps.devices` & `apps.unlock_requests` (Protection Mono-Appareil)
- `apps.devices` : Enregistre l'empreinte de l'appareil (`device_identifier`, nom, plateforme, dernière date de présence). Interdit à un compte de télécharger sur deux appareils différents simultanément.
- `apps.unlock_requests` : Permet à un étudiant qui a changé de téléphone de soumettre une demande de déblocage avec un motif. L'administrateur peut approuver (ce qui détache l'ancien appareil) ou rejeter la demande.

#### 8. `apps.audit` & `apps.statistics` (Gouvernance Administrateur)
- `apps.audit` : Middleware et fonction utilitaire `log_action` enregistrant chaque fait sensible (connexion, téléchargement de token, modification d'épreuve, suspension d'utilisateur, validation de paiement) avec IP et horodatage.
- `apps.statistics` : Agrège le chiffre d'affaires total, le nombre d'étudiants, d'épreuves, d'achats et la liste des ventes récentes pour le tableau de bord mobile.

#### 9. `apps.core_utils` (Sécurité & Robustesse)
- `permissions.py` : Classes `IsAdminRole` et `IsStudentRole` garantissant que le rôle est re-vérifié systématiquement en base sur chaque requête.
- `exceptions.py` : Intercepte les erreurs DRF et les exceptions non gérées pour renvoyer des messages d'erreur propres et génériques sans jamais exposer de stack trace technique aux utilisateurs.

---

## 4. Architecture Détaillée du Mobile (Flutter)

L'application Flutter adopte une architecture réactive propre inspirée du pattern **Clean Architecture / Feature-Driven** :

```
mobile/
├── pubspec.yaml              # Dépendances (dio, go_router, provider, file_picker, kkiapay, pdfx)
├── android/                  # Fichiers natifs Android (Manifest, Gradle, Keystore)
├── ios/                      # Fichiers natifs iOS (Info.plist, Pods, Keychain)
├── test/                     # Tests unitaires et tests de widgets Flutter
│   └── widget_test.dart      # Test de rendu global de l'application
└── lib/
    ├── main.dart             # Point d'entrée de l'application Flutter
    ├── core/                 # Socle transversal et services techniques
    │   ├── constants/        # URLs des endpoints API et constantes globales
    │   ├── errors/           # Exceptions métier typées côté client
    │   ├── network/          # Client Dio avec intercepteurs et retry sur 401
    │   ├── routing/          # Routeur GoRouter avec déclarations des écrans
    │   ├── security/         # Chiffrement/déchiffrement local AES
    │   ├── storage/          # Stockage sécurisé des tokens (Keystore/Keychain)
    │   ├── theme/            # Chartes graphiques (Palette Étudiant et Admin)
    │   └── utils/            # Utilitaires de formatage de dates et monnaies
    ├── models/               # Entités métier Dart
    ├── repositories/         # Couche d'accès aux données distantes (Appels HTTP)
    ├── providers/            # Couche de gestion d'état réactive (ChangeNotifier)
    ├── widgets/              # Composants graphiques réutilisables
    └── features/             # Écrans et interfaces découpés par domaine
        ├── auth/             # Authentification (Splash, Login, Register, Forgot Password)
        ├── student/          # Espace Étudiant (Navigation, Catalogue, Lecteur, Profil)
        └── admin/            # Espace Administrateur (Dashboard, CRUD Épreuves, Audit)
```

### Socle Technique & Core (`lib/core/`)

| Fichier / Dossier | Rôle & Description |
|-------------------|--------------------|
| `constants/api_constants.dart` | Centralise toutes les routes relatives de l'API et gère l'URL de base dynamique via `String.fromEnvironment('API_BASE_URL')`. |
| `network/api_client.dart` | Singleton Dio qui injecte automatiquement le header `Authorization: Bearer <token>`, gère la déconnexion et le rafraîchissement transparent du jeton sur code HTTP 401. |
| `storage/secure_storage.dart` | Encapsule `flutter_secure_storage` pour écrire et lire les tokens JWT et le rôle dans l'espace matériellement sécurisé du smartphone. |
| `security/local_encryption_service.dart` | Service cryptographique gérant une clé AES aléatoire persistée en Keystore. Fournit `encryptToFile` et `decryptFromFile` pour garantir qu'aucun PDF ne reste en clair sur l'espace de stockage de l'appareil. |
| `routing/app_router.dart` | Instance `GoRouter` déclarant toutes les routes de l'application (`/splash`, `/login`, `/register`, `/student`, `/admin`, etc.) avec passage d'arguments sécurisés. |
| `theme/app_theme.dart` | Définit le design system : couleurs primaires, cartes en élévation douce, typographie moderne et contrastes adaptés pour l'interface étudiant et l'interface admin. |
| `errors/app_exception.dart` | Traduit les codes d'erreur réseau en messages explicites et conviviaux pour l'utilisateur. |

---

### Données & Métier

#### Modèles (`lib/models/`)
- `user.dart` : Représentation de l'utilisateur avec son rôle (`UserRole.student` ou `UserRole.admin`).
- `exam.dart` : Objet épreuve (titre, filière, matière, prix, nombre de pages, statut).
- `purchase.dart` : Achat réalisé avec statut de validité et nombre de téléchargements.
- `transaction.dart` : Détails de la transaction financière KkiaPay.
- `device.dart`, `filiere.dart`, `matiere.dart`, `notification_item.dart`.

#### Repositories (`lib/repositories/`)
Intermédiaires entre l'API HTTP et les providers de l'application :
- `auth_repository.dart` : Appel de connexion, inscription, profil et révocation de session.
- `catalogue_repository.dart` : Récupération des filières, matières et épreuves publiées.
- `payment_repository.dart` : Déclenchement de l'initiation de paiement et transmission de la référence de paiement à `/api/payments/verify/`.
- `purchase_repository.dart` : Liste des achats et demande de jeton `DownloadToken`.
- `admin_repository.dart` : Gestion des statistiques, du CRUD épreuves (supportant `FormData` multipart pour le fichier PDF), des utilisateurs et des demandes de déblocage.

#### Providers (`lib/providers/`)
Gèrent l'état global et notifient l'interface graphique :
- `auth_provider.dart` : Statut de connexion (`authenticated`, `unauthenticated`), utilisateur courant, booléen `isAdmin`.
- `catalogue_provider.dart` : Liste des filières, épreuves actives, filtres sélectionnés et recherche.
- `purchase_provider.dart` : Liste et actualisation des achats de l'étudiant.
- `notification_provider.dart` : Suivi du compteur d'alertes non lues.
- `admin_provider.dart` : KPIs statistiques et alertes d'administration.

---

### Interfaces Utilisateur (`features/`)

#### Espace Authentification (`features/auth/`)
- `splash/splash_screen.dart` : Écran de démarrage qui interroge la session chiffrée locale et oriente automatiquement l'utilisateur vers `/admin`, `/student` ou `/login`.
- `login/login_screen.dart` : Formulaire de connexion épuré avec masquage de mot de passe et mémorisation sécurisée.
- `register/register_screen.dart` : Création de compte étudiant.

#### Espace Étudiant (`features/student/`)
- `dashboard/student_shell.dart` : Barre de navigation inférieure avec 5 onglets : **Accueil**, **Catalogue**, **Achats**, **Alertes**, **Profil**.
- `dashboard/home_tab.dart` : Carrousel d'épreuves récentes, filtres par filière et aperçu des derniers achats.
- `catalogue/catalogue_screen.dart` : Recherche avancée et filtrage dynamique du catalogue.
- `exam_details/exam_details_screen.dart` : Présentation complète de l'épreuve avec rappel des garanties de sécurité et bouton d'achat.
- `payment/payment_screen.dart` : Déclenchement du widget natif **KkiaPay** et vérification serveur en temps réel.
- `reader/secure_reader_screen.dart` : **Lecteur PDF haute sécurité**. Déchiffre les octets en mémoire vive (`pdfx`), applique un filigrane transparent nominatif dynamique (Nom de l'étudiant, identifiant, horodatage) et fonctionne 100% hors-ligne après le premier téléchargement.
- `purchases/purchases_screen.dart` : Suivi des épreuves acquises avec filtres (Téléchargées / À télécharger).
- `devices/devices_screen.dart` & `unlock_requests/` : Consultation de l'appareil actif et formulaire de demande de réinitialisation.

#### Espace Administrateur (`features/admin/`)
- `dashboard/admin_shell.dart` & `admin_home_tab.dart` : Tableau de bord exécutif affichant le Chiffre d'Affaires, le nombre d'étudiants, le nombre d'épreuves, les alertes de déblocage et les ventes en direct.
- `exams/manage_exams_screen.dart` : Liste des épreuves avec filtres (Toutes, Publiées, Brouillons, Archivées) et actions (Modifier, Archiver, Supprimer).
- `exams/exam_form_screen.dart` : Formulaire de saisie d'épreuve avec sélecteur natif de fichier PDF (`file_picker`) et transmission multipart `FormData`.
- `filieres/` & `matieres/` : Interfaces de gestion des structures académiques.
- `users/manage_users_screen.dart` : Liste des étudiants et action de suspension immédiate de compte.
- `transactions/`, `purchases/`, `unlock_requests/` & `audit/` : Suivi financier, traitement des déblocages et inspection des journaux de sécurité.

---

## 5. Flux de Sécurité et d'Échange de Données

### A. Flux d'Achat Sécurisé (KkiaPay)
```
[Étudiant sur Mobile]
       │
       ▼
 1. Clic "Payer" ───► POST /api/payments/initiate/ ───► [Django]
                                                          │ Renvoie clé publique + montant exact
       ┌──────────────────────────────────────────────────┘
       ▼
 2. Ouverture du Widget KKiaPay (Mobile Money / Carte)
       │
       ▼ Validation du paiement par l'opérateur
 3. Callback KKiaPay retourne `transactionId`
       │
       ▼
 4. POST /api/payments/verify/ { ref: transactionId } ──► [Django]
                                                            │ Interroge l'API KkiaPay officielle
                                                            │ Vérifie : Statut=SUCCESS & Montant=OK
                                                            ▼
                                                     Crée Achat + Transaction (idempotent)
                                                            │
       ┌────────────────────────────────────────────────────┘
       ▼
 5. Confirmation reçue (201 Created)
       │
       ▼
 Épreuve débloquée dans "Mes achats" sur le mobile
```

---

### B. Flux de Téléchargement & Lecture Sécurisée (Anti-Fuite)
```
[Lecteur Mobile]
       │
       ▼
 1. Demande de jeton ──► POST /api/purchases/<id>/download-token/ ──► [Django]
                                                                        │ Vérifie achat valide
                                                                        │ Vérifie appareil actif
                                                                        ▼
                                                                 Génère Token temporaire (TTL 15 min)
       ┌────────────────────────────────────────────────────────────────┘
       ▼
 2. Téléchargement ────► POST /api/downloads/file/ { token } ──────► [Django]
                                                                        │ Consomme le jeton (usage unique)
                                                                        │ Lit le fichier dans media_private/
                                                                        ▼
                                                                 Stream binaire du PDF
       ┌────────────────────────────────────────────────────────────────┘
       ▼
 3. Réception du flux binaire en mémoire
       │
       ▼
 4. Chiffrement AES immédiat sur le disque du smartphone
    (clé secrète stockée dans Android Keystore / iOS Keychain)
    Fichier : `exam_<hash>.enc`
       │
       ▼
 5. Déchiffrement à la volée en mémoire vive (Uint8List)
       │
       ▼
 6. Moteur PdfView (pdfx) + Filigrane dynamique inamovible
    (Nom, Identifiant étudiant, Date du jour)
```
