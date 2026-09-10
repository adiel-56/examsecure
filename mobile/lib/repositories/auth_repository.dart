import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/user.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final access = response.data['access'] as String;
      final refresh = response.data['refresh'] as String;
      final userJson = response.data['user'] as Map<String, dynamic>;

      await SecureStorage.instance.saveTokens(access: access, refresh: refresh);
      final user = AppUser.fromJson(userJson);
      await SecureStorage.instance.saveRole(userJson['role']);
      await SecureStorage.instance.saveUserId(user.id);
      return user;
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    int? filiereId,
  }) async {
    try {
      await _dio.post(
        ApiConstants.register,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'password': password,
          if (filiereId != null) 'filiere': filiereId,
        },
      );
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await SecureStorage.instance.refreshToken;
      if (refresh != null) {
        await _dio.post(ApiConstants.logout, data: {'refresh': refresh});
      }
    } catch (_) {
      // La déconnexion locale doit réussir même si l'appel réseau échoue.
    } finally {
      await SecureStorage.instance.clearSession();
    }
  }

  Future<AppUser> fetchProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      return AppUser.fromJson(response.data);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<bool> hasActiveSession() async {
    final token = await SecureStorage.instance.accessToken;
    return token != null;
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        ApiConstants.passwordReset,
        data: {'email': email},
      );
      return response.data['message'] as String? ?? 'Demande traitée.';
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
