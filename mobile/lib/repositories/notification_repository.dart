import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<AppNotification>> fetchAll() async {
    try {
      final response = await _dio.get(ApiConstants.notifications);
      final results = response.data['results'] ?? response.data;
      return (results as List).map((e) => AppNotification.fromJson(e)).toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.patch('${ApiConstants.notifications}$id/read/');
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
