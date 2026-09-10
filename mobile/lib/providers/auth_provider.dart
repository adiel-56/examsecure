import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../core/storage/secure_storage.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Le rôle affiché ici ne sert qu'à orienter la navigation Flutter
/// (section 6 du cahier des charges) : Django reste l'autorité finale
/// pour toute action sensible, quel que soit ce que Flutter affiche.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  String? errorMessage;
  bool isLoading = false;

  Future<void> checkSession() async {
    final hasSession = await _repository.hasActiveSession();
    if (!hasSession) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      currentUser = await _repository.fetchProfile();
      status = AuthStatus.authenticated;
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _repository.login(email: email, password: password);
      status = AuthStatus.authenticated;
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    int? filiereId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        filiereId: filiereId,
      );
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<String?> forgotPassword({required String email}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final msg = await _repository.forgotPassword(email: email);
      return msg;
    } on AppException catch (e) {
      errorMessage = e.message;
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get isAdmin => currentUser?.role == UserRole.admin;

  static Future<String?> readStoredRole() => SecureStorage.instance.role;
}
