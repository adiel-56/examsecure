import '../core/constants/api_constants.dart';

class Purchase {
  final int id;
  final int documentId;
  final String documentTitre;
  final double documentPrix;
  final String? couvertureUrl;
  final String statut;
  final int nombreTelechargements;
  final DateTime? datePremierTelechargement;
  final DateTime createdAt;

  Purchase({
    required this.id,
    required this.documentId,
    required this.documentTitre,
    required this.documentPrix,
    this.couvertureUrl,
    required this.statut,
    required this.nombreTelechargements,
    this.datePremierTelechargement,
    required this.createdAt,
  });

  // Rétro-compatibilité
  int get epreuveId => documentId;
  String get epreuveTitre => documentTitre;
  double get epreuvePrix => documentPrix;

  bool get peutTelecharger => statut == 'VALID' && nombreTelechargements < 1;

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

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
        id: json['id'],
        documentId: json['document'] ?? json['epreuve'] ?? 0,
        documentTitre: json['document_titre'] ?? json['epreuve_titre'] ?? '',
        documentPrix: double.tryParse('${json['document_prix'] ?? json['epreuve_prix']}') ?? 0,
        couvertureUrl: json['couverture_url'] ?? json['couverture'],
        statut: json['statut'] ?? 'VALID',
        nombreTelechargements: json['nombre_telechargements'] ?? 0,
        datePremierTelechargement: json['date_premier_telechargement'] != null
            ? DateTime.tryParse(json['date_premier_telechargement'])
            : null,
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}
