import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/payment_config.dart';
import '../models/transaction.dart';

class PaymentRepository {
  final Dio _dio = ApiClient.instance.dio;

  /// Récupère la configuration Mobile Money de l'administration (numéro, nom, instructions).
  Future<PaymentConfig> fetchConfig() async {
    try {
      final response = await _dio.get(ApiConstants.paymentConfig);
      return PaymentConfig.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Soumet le reçu de paiement manuel par Mobile Money (Multipart).
  Future<AppTransaction> submitReceipt({
    required int examId,
    double? amount,
    required String phoneNumber,
    String? referenceRecu,
    String? commentaire,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'document_id': examId,
        'epreuve_id': examId,
        if (amount != null) 'montant': amount,
        'numero_telephone': phoneNumber,
        if (referenceRecu != null && referenceRecu.isNotEmpty) 'reference_recu': referenceRecu,
        if (commentaire != null && commentaire.isNotEmpty) 'commentaire_etudiant': commentaire,
        'recu_fichier': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        ApiConstants.paymentSubmitReceipt,
        data: formData,
      );
      return AppTransaction.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Récupère le statut actuel du paiement pour un document.
  Future<Map<String, dynamic>> fetchPaymentStatus(int examId) async {
    try {
      final response = await _dio.get(
        ApiConstants.paymentStatus,
        queryParameters: {'document_id': examId, 'epreuve_id': examId},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Historique des transactions de l'étudiant.
  Future<List<AppTransaction>> fetchMyTransactions() async {
    try {
      final response = await _dio.get(ApiConstants.paymentHistory);
      final list = (response.data as List<dynamic>)
          .map((j) => AppTransaction.fromJson(j as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  // Anciennes méthodes KkiaPay conservées pour rétro-compatibilité
  Future<Map<String, dynamic>> initiate(int examId) async {
    try {
      final response = await _dio.post(ApiConstants.paymentInitiate, data: {
        'document_id': examId,
        'epreuve_id': examId,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<Map<String, dynamic>> verify({
    required int examId,
    required String referenceKkiapay,
    String moyenPaiement = 'MOBILE_MONEY',
  }) async {
    try {
      final response = await _dio.post(ApiConstants.paymentVerify, data: {
        'document_id': examId,
        'epreuve_id': examId,
        'reference_kkiapay': referenceKkiapay,
        'moyen_paiement': moyenPaiement,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
