/// URL de l'API centralisée ici :
/// ne jamais disperser l'URL dans plusieurs fichiers.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String refresh = '/auth/refresh/';
  static const String logout = '/auth/logout/';
  static const String profile = '/auth/profile/';
  static const String passwordReset = '/auth/password-reset/';

  static const String filieres = '/filieres/';
  static const String matieres = '/matieres/';
  static const String documents = '/documents/';
  static const String exams = '/documents/';  // Rétro-compatibilité

  // Paiement Manuel Mobile Money
  static const String paymentConfig = '/payments/config/';
  static const String paymentSubmitReceipt = '/payments/submit-receipt/';
  static const String paymentStatus = '/payments/status/';
  static const String paymentHistory = '/payments/history/';

  // KkiaPay (rétro-compatibilité)
  static const String paymentInitiate = '/payments/initiate/';
  static const String paymentVerify = '/payments/verify/';

  static const String purchases = '/purchases/';
  static const String downloadsFile = '/downloads/file/';

  static const String devices = '/devices/';
  static const String devicesRegister = '/devices/register/';

  static const String unlockRequests = '/unlock-requests/';

  static const String notifications = '/notifications/';

  // Administration
  static const String adminUsers = '/admin/users/';
  static const String adminFilieres = '/admin/filieres/';
  static const String adminMatieres = '/admin/matieres/';
  static const String adminDocuments = '/admin/documents/';
  static const String adminExams = '/admin/documents/';  // Rétro-compatibilité
  static const String adminTransactions = '/admin/transactions/';
  static const String adminPaymentConfig = '/admin/payments/config/';
  static const String adminPurchases = '/admin/purchases/';
  static const String adminUnlockRequests = '/admin/unlock-requests/';
  static const String adminStatistics = '/admin/statistics/';
  static const String adminAuditLogs = '/admin/audit-logs/';
}
