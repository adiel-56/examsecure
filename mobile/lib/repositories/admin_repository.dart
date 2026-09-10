import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/payment_config.dart';
import '../models/transaction.dart';

/// Regroupe tous les appels administrateur. Le rôle ADMIN est de toute
/// façon revérifié côté Django pour chaque endpoint (403 sinon) : cette
/// couche ne fait qu'exposer les appels côté Flutter.
class AdminRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> fetchStatistics() async {
    try {
      final response = await _dio.get(ApiConstants.adminStatistics);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  // --- Gestion Paiement Mobile Money ---
  Future<PaymentConfig> fetchPaymentConfig() async {
    try {
      final response = await _dio.get(ApiConstants.adminPaymentConfig);
      return PaymentConfig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<PaymentConfig> updatePaymentConfig(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConstants.adminPaymentConfig, data: data);
      return PaymentConfig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<List<AppTransaction>> fetchTransactions({String? statut, String? search}) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminTransactions,
        queryParameters: {
          if (statut != null && statut.isNotEmpty) 'statut': statut,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final rawList = response.data['results'] ?? response.data;
      return (rawList as List<dynamic>)
          .map((j) => AppTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<AppTransaction> fetchTransactionDetail(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.adminTransactions}$id/');
      return AppTransaction.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> validateTransaction(int id) async {
    try {
      await _dio.post('${ApiConstants.adminTransactions}$id/validate/');
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> rejectTransaction(int id, {required String motif}) async {
    try {
      await _dio.post(
        '${ApiConstants.adminTransactions}$id/reject/',
        data: {'motif_refus': motif},
      );
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  // --- Utilisateurs, Filières, Matières, Documents ---
  Future<List<dynamic>> fetchUsers({String? search}) => _list(ApiConstants.adminUsers, search: search);
  Future<List<dynamic>> fetchFilieres() => _list(ApiConstants.adminFilieres);
  Future<List<dynamic>> fetchMatieres() => _list(ApiConstants.adminMatieres);
  Future<List<dynamic>> fetchDocuments({String? statut}) =>
      _list(ApiConstants.adminDocuments, extra: statut != null ? {'statut': statut} : null);
  Future<List<dynamic>> fetchExams({String? statut}) => fetchDocuments(statut: statut);
  Future<List<dynamic>> fetchPurchases() => _list(ApiConstants.adminPurchases);
  Future<List<dynamic>> fetchUnlockRequests({String? statut}) =>
      _list(ApiConstants.adminUnlockRequests, extra: statut != null ? {'statut': statut} : null);
  Future<List<dynamic>> fetchAuditLogs() => _list(ApiConstants.adminAuditLogs);

  Future<void> createFiliere(Map<String, dynamic> data) => _post(ApiConstants.adminFilieres, data);
  Future<void> updateFiliere(int id, Map<String, dynamic> data) =>
      _patch('${ApiConstants.adminFilieres}$id/', data);
  Future<void> deleteFiliere(int id) => _delete('${ApiConstants.adminFilieres}$id/');

  Future<void> createMatiere(Map<String, dynamic> data) => _post(ApiConstants.adminMatieres, data);
  Future<void> updateMatiere(int id, Map<String, dynamic> data) =>
      _patch('${ApiConstants.adminMatieres}$id/', data);
  Future<void> deleteMatiere(int id) => _delete('${ApiConstants.adminMatieres}$id/');

  Future<void> createDocument(dynamic data) => _post(ApiConstants.adminDocuments, data);
  Future<void> updateDocument(int id, dynamic data) => _patch('${ApiConstants.adminDocuments}$id/', data);
  Future<void> deleteDocument(int id) => _delete('${ApiConstants.adminDocuments}$id/');

  Future<void> createExam(dynamic data) => createDocument(data);
  Future<void> updateExam(int id, dynamic data) => updateDocument(id, data);
  Future<void> deleteExam(int id) => deleteDocument(id);

  Future<void> toggleUserActive(int id) => _patch('${ApiConstants.adminUsers}$id/toggle-active/', {});

  Future<void> resolveUnlockRequest(int id, {required String statut, String? reponseAdmin}) =>
      _patch('${ApiConstants.adminUnlockRequests}$id/', {
        'statut': statut,
        if (reponseAdmin != null) 'reponse_admin': reponseAdmin,
      });

  Future<List<dynamic>> _list(String path, {String? search, Map<String, dynamic>? extra}) async {
    try {
      final response = await _dio.get(path, queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        ...?extra,
      });
      final results = response.data['results'] ?? response.data;
      return results as List<dynamic>;
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> _post(String path, dynamic data) async {
    try {
      await _dio.post(path, data: data);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> _patch(String path, dynamic data) async {
    try {
      await _dio.patch(path, data: data);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> _delete(String path) async {
    try {
      await _dio.delete(path);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
