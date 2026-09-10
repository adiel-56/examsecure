class UnlockRequest {
  final int id;
  final int achatId;
  final String documentTitre;
  final String motif;
  final String statut;
  final String reponseAdmin;
  final DateTime createdAt;

  UnlockRequest({
    required this.id,
    required this.achatId,
    required this.documentTitre,
    required this.motif,
    required this.statut,
    required this.reponseAdmin,
    required this.createdAt,
  });

  // Rétro-compatibilité
  String get epreuveTitre => documentTitre;

  factory UnlockRequest.fromJson(Map<String, dynamic> json) => UnlockRequest(
        id: json['id'],
        achatId: json['achat'],
        documentTitre: json['document_titre'] ?? json['epreuve_titre'] ?? '',
        motif: json['motif'] ?? '',
        statut: json['statut'] ?? 'PENDING',
        reponseAdmin: json['reponse_admin'] ?? '',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}
