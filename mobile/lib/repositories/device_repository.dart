import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/device.dart';

class DeviceRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<AppDevice>> fetchMyDevices() async {
    try {
      final response = await _dio.get(ApiConstants.devices);
      final results = response.data['results'] ?? response.data;
      return (results as List).map((e) => AppDevice.fromJson(e)).toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> registerCurrentDevice({
    required String deviceIdentifier,
    required String platform,
    required String deviceName,
    required String appVersion,
  }) async {
    try {
      await _dio.post(ApiConstants.devicesRegister, data: {
        'device_identifier': deviceIdentifier,
        'platform': platform,
        'device_name': deviceName,
        'app_version': appVersion,
      });
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<void> removeDevice(int id) async {
    try {
      await _dio.delete('${ApiConstants.devices}$id/');
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
