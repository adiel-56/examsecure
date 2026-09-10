import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../models/purchase.dart';
import '../repositories/purchase_repository.dart';

class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepository _repository = PurchaseRepository();

  List<Purchase> purchases = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadPurchases() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      purchases = await _repository.fetchMyPurchases();
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
