/// Exception applicative générique, sans jamais exposer de détails
/// techniques sensibles à l'utilisateur (section 37 du cahier des charges).
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  factory AppException.fromStatusCode(int code, [String? serverMessage]) {
    switch (code) {
      case 400:
        return AppException(
          serverMessage ?? 'Requête invalide.',
          statusCode: code,
        );
      case 401:
        return AppException(
          'Session expirée, veuillez vous reconnecter.',
          statusCode: code,
        );
      case 403:
        return AppException(
          'Vous n\'avez pas la permission d\'effectuer cette action.',
          statusCode: code,
        );
      case 404:
        return AppException('Ressource introuvable.', statusCode: code);
      case 409:
        return AppException(
          serverMessage ?? 'Conflit détecté.',
          statusCode: code,
        );
      case 422:
        return AppException(
          serverMessage ?? 'Données invalides.',
          statusCode: code,
        );
      case 429:
        return const AppException(
          'Trop de requêtes, veuillez patienter.',
          statusCode: 429,
        );
      case 500:
        return const AppException(
          'Erreur serveur. Merci de réessayer plus tard.',
          statusCode: 500,
        );
      case 503:
        return const AppException(
          'Service indisponible pour le moment.',
          statusCode: 503,
        );
      default:
        return AppException(
          serverMessage ?? 'Une erreur est survenue.',
          statusCode: code,
        );
    }
  }

  static const noInternet = AppException(
    'Impossible de joindre le serveur. Vérifiez votre connexion ou l\'adresse du serveur.',
  );
  static const timeout = AppException(
    'Le serveur met trop de temps à répondre.',
  );

  @override
  String toString() => message;
}
