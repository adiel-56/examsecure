import '../core/constants/api_constants.dart';

enum ExamStatus { draft, published, archived }

ExamStatus examStatusFromString(String value) {
  switch (value) {
    case 'PUBLISHED':
      return ExamStatus.published;
    case 'ARCHIVED':
      return ExamStatus.archived;
    default:
      return ExamStatus.draft;
  }
}

class Exam {
  final int id;
  final String titre;
  final String description;
  final List<int> matieres;
  final List<String> matieresNoms;
  final int matiereId;
  final String matiereNom;
  final int filiereId;
  final String filiereNom;
  final String anneeAcademique;
  final double prix;
  final String devise;
  final int nombrePages;
  final String typeContenu;
  final String? couvertureUrl;
  final ExamStatus statut;

  Exam({
    required this.id,
    required this.titre,
    required this.description,
    this.matieres = const [],
    this.matieresNoms = const [],
    required this.matiereId,
    required this.matiereNom,
    required this.filiereId,
    required this.filiereNom,
    required this.anneeAcademique,
    required this.prix,
    required this.devise,
    required this.nombrePages,
    required this.typeContenu,
    this.couvertureUrl,
    required this.statut,
  });

  bool get isMultiMatiere => matieres.length > 1;
  String get matieresDisplay =>
      matieresNoms.isNotEmpty ? matieresNoms.join(' · ') : matiereNom;

  String? get fullCouvertureUrl {
    if (couvertureUrl == null || couvertureUrl!.trim().isEmpty) return null;
    final url = couvertureUrl!.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    const base = ApiConstants.baseUrl;
    final origin = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : (base.endsWith('/api/') ? base.substring(0, base.length - 5) : base);
    return '$origin${url.startsWith('/') ? '' : '/'}$url';
  }

  factory Exam.fromJson(Map<String, dynamic> json) {
    final rawMatieres = json['matieres'];
    final List<int> matieresList = (rawMatieres is List)
        ? rawMatieres
            .map((e) => int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList()
        : (json['matiere'] != null
            ? [int.tryParse('${json['matiere']}') ?? 0]
                .where((e) => e > 0)
                .toList()
            : []);

    final rawNoms = json['matieres_noms'];
    final List<String> nomsList = (rawNoms is List)
        ? rawNoms.map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : ((json['matiere_nom'] != null &&
                '${json['matiere_nom']}'.trim().isNotEmpty)
            ? '${json['matiere_nom']}'
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : []);

    final String singleNom = (json['matiere_nom'] != null &&
            '${json['matiere_nom']}'.trim().isNotEmpty)
        ? '${json['matiere_nom']}'.trim()
        : (nomsList.isNotEmpty ? nomsList.join(', ') : '');

    final int singleId = json['matiere'] != null
        ? (int.tryParse('${json['matiere']}') ?? 0)
        : (matieresList.isNotEmpty ? matieresList.first : 0);

    return Exam(
      id: json['id'],
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      matieres: matieresList,
      matieresNoms: nomsList,
      matiereId: singleId,
      matiereNom: singleNom,
      filiereId: json['filiere'] ?? 0,
      filiereNom: json['filiere_nom'] ?? '',
      anneeAcademique: json['annee_academique'] ?? '',
      prix: double.tryParse('${json['prix']}') ?? 0,
      devise: json['devise'] ?? 'XOF',
      nombrePages: json['nombre_pages'] ?? 0,
      typeContenu: json['type_contenu'] ?? 'EXAM',
      couvertureUrl: json['couverture_url'] ?? json['couverture'],
      statut: examStatusFromString(json['statut'] ?? 'DRAFT'),
    );
  }
}

typedef AppDocument = Exam;
