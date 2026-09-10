import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/exam.dart';
import '../models/filiere.dart';
import '../models/matiere.dart';

class CatalogueRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Filiere>> fetchFilieres() async {
    try {
      final response = await _dio.get(ApiConstants.filieres);
      final results = response.data['results'] ?? response.data;
      return (results as List).map((e) => Filiere.fromJson(e)).toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<List<Matiere>> fetchMatieres({int? filiereId}) async {
    try {
      final response = await _dio.get(ApiConstants.matieres, queryParameters: {
        if (filiereId != null) 'filiere': filiereId,
      });
      final results = response.data['results'] ?? response.data;
      return (results as List).map((e) => Matiere.fromJson(e)).toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<List<Exam>> fetchExams({String? search, int? filiereId, int? matiereId}) async {
    try {
      final response = await _dio.get(ApiConstants.exams, queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (filiereId != null) 'filiere': filiereId,
        if (matiereId != null) 'matiere': matiereId,
      });
      final results = response.data['results'] ?? response.data;
      return (results as List).map((e) => Exam.fromJson(e)).toList();
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }

  Future<Exam> fetchExamDetail(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.exams}$id/');
      return Exam.fromJson(response.data);
    } catch (e) {
      throw ApiClient.instance.mapError(e);
    }
  }
}
