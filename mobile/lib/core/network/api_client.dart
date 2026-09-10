import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage.dart';

/// Client HTTP central. Gère automatiquement :
/// - l'ajout du header Authorization
/// - le rafraîchissement du token à l'expiration (401)
/// - la traduction des erreurs réseau en AppException
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      ),
    );
    _dio.interceptors.add(_authInterceptor());
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  bool _isRefreshing = false;

  Dio get dio => _dio;

  void updateBaseUrl(String newUrl) {
    final clean = newUrl.trim();
    if (clean.isNotEmpty) {
      _dio.options.baseUrl = clean;
    }
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final customUrl = await SecureStorage.instance.baseUrl;
        if (customUrl != null && customUrl.trim().isNotEmpty) {
          options.baseUrl = customUrl.trim();
        }
        final token = await SecureStorage.instance.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final isRefreshCall = error.requestOptions.path == ApiConstants.refresh;

        if (isUnauthorized && !isRefreshCall && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshed = await _tryRefreshToken();
            _isRefreshing = false;
            if (refreshed) {
              final cloned = await _retry(error.requestOptions);
              return handler.resolve(cloned);
            }
          } catch (_) {
            _isRefreshing = false;
          }
        }
        handler.next(error);
      },
    );
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = await SecureStorage.instance.refreshToken;
    if (refresh == null) return false;
    try {
      final response = await _dio.post(ApiConstants.refresh, data: {'refresh': refresh});
      final newAccess = response.data['access'] as String?;
      if (newAccess == null) return false;
      final currentRefresh = response.data['refresh'] as String? ?? refresh;
      await SecureStorage.instance.saveTokens(access: newAccess, refresh: currentRefresh);
      return true;
    } catch (_) {
      await SecureStorage.instance.clearSession();
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) {
    final options = Options(method: requestOptions.method, headers: requestOptions.headers);
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Traduit toute DioException en AppException lisible, sans détail technique.
  AppException mapError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return AppException.timeout;
      }
      if (error.type == DioExceptionType.connectionError) {
        return AppException.noInternet;
      }
      final code = error.response?.statusCode;
      String? serverMessage;
      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        final details = data['details'];
        if (details is Map && details.isNotEmpty) {
          final parts = <String>[];
          details.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              parts.add(value.join(', '));
            } else if (value is String) {
              parts.add(value);
            }
          });
          if (parts.isNotEmpty) {
            serverMessage = parts.join('\n');
          }
        } else if (details is String && details.isNotEmpty) {
          serverMessage = details;
        } else if (data['message'] != null && data['message'] != 'Requête invalide.') {
          serverMessage = data['message']?.toString();
        } else if (data['detail'] != null) {
          serverMessage = data['detail']?.toString();
        }
      }
      if (code != null) {
        return AppException.fromStatusCode(code, serverMessage);
      }
    }
    return const AppException('Une erreur inattendue est survenue.');
  }
}
