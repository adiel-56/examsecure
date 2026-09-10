import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/unlock_request.dart';

class UnlockRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<UnlockRequest>> fetchMyRequests() async {
    try {
      final response = await _dio.get(ApiConstants.unlockRequests);
      final results = response.data['results'] ?? response.data;
      return (results as List).map((e) => UnlockRequest.fromJson(e)).toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> createRequest({required int achatId, int? appareilId, required String motif}) async {
    try {
      await _dio.post(ApiConstants.unlockRequests, data: {
        'achat': achatId,
        if (appareilId != null) 'appareil_actuel': appareilId,
        'motif': motif,
      });
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
