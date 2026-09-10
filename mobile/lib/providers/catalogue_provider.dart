import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../models/exam.dart';
import '../models/filiere.dart';
import '../models/matiere.dart';
import '../repositories/catalogue_repository.dart';

class CatalogueProvider extends ChangeNotifier {
  final CatalogueRepository _repository = CatalogueRepository();

  List<Exam> exams = [];
  List<Exam> get documents => exams;
  List<Filiere> filieres = [];
  List<Matiere> matieres = [];
  bool isLoading = false;
  String? errorMessage;

  int? selectedFiliereId;
  int? selectedMatiereId;
  String searchQuery = '';

  Future<void> loadFilieres() async {
    try {
      filieres = await _repository.fetchFilieres();
      notifyListeners();
    } on AppException catch (e) {
      errorMessage = e.message;
    }
  }

  Future<void> loadExams() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      exams = await _repository.fetchExams(
        search: searchQuery,
        filiereId: selectedFiliereId,
        matiereId: selectedMatiereId,
      );
    } on AppException catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    searchQuery = value;
    loadExams();
  }

  void setFiliereFilter(int? id) {
    selectedFiliereId = id;
    loadExams();
  }
}
