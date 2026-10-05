import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class CacheInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.requestOptions.method.toUpperCase() == 'GET' && response.statusCode == 200) {
      try {
        final file = await _getCacheFile(response.requestOptions.uri.toString());
        await file.writeAsString(jsonEncode(response.data));
      } catch (_) {
        // Ignorer les erreurs d'écriture de cache
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.unknown) {
      if (err.requestOptions.method.toUpperCase() == 'GET') {
        try {
          final file = await _getCacheFile(err.requestOptions.uri.toString());
          if (await file.exists()) {
            final data = await file.readAsString();
            final json = jsonDecode(data);
            return handler.resolve(
              Response(
                requestOptions: err.requestOptions,
                data: json,
                statusCode: 200,
              ),
            );
          }
        } catch (_) {
          // Si le cache échoue, on continue avec l'erreur
        }
      }
    }
    super.onError(err, handler);
  }

  Future<File> _getCacheFile(String url) async {
    final dir = await getApplicationSupportDirectory();
    final bytes = utf8.encode(url);
    final hash = bytes.fold<int>(0, (prev, element) => prev + element).toString();
    return File('${dir.path}/cache_$hash.json');
  }
}
