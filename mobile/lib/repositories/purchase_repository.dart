import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/purchase.dart';
import 'device_repository.dart';

class PurchaseRepository {
  final Dio _dio = ApiClient.instance.dio;
  final DeviceRepository _deviceRepository = DeviceRepository();

  Future<void> registerCurrentDevice(String deviceIdentifier) {
    return _deviceRepository.registerCurrentDevice(
      deviceIdentifier: deviceIdentifier,
      platform: 'android',
      deviceName: 'Appareil ExamSecure',
      appVersion: '1.0.0',
    );
  }

  Future<List<Purchase>> fetchMyPurchases() async {
    try {
      final response = await _dio.get(ApiConstants.purchases);
      final results = response.data['results'] ?? response.data;
      return (results as List).map((e) => Purchase.fromJson(e)).toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  /// Demande un DownloadToken temporaire pour un achat (section 16/24).
  Future<String> requestDownloadToken(
    int purchaseId, {
    required String deviceIdentifier,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.purchases}$purchaseId/download/',
        data: {'device_identifier': deviceIdentifier},
      );
      return response.data['download_token'] as String;
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
