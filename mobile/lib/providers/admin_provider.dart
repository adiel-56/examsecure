import 'package:flutter/foundation.dart';
import '../repositories/admin_repository.dart';

/// Provider générique pour le dashboard admin. Chaque écran admin recharge
/// ses propres données ; ce provider centralise les statistiques globales
/// utilisées sur l'écran d'accueil administrateur.
class AdminProvider extends ChangeNotifier {
  final AdminRepository repository = AdminRepository();

  Map<String, dynamic>? statistics;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadStatistics() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      statistics = await repository.fetchStatistics();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
