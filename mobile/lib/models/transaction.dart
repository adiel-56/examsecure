import '../core/constants/api_constants.dart';

class AppTransaction {
  final int id;
  final int? documentId;
  final String documentTitre;
  final double documentPrix;
  final double montant;
  final String devise;
  final String moyenPaiement;
  final String referenceKkiapay;
  final String numeroTelephone;
  final String referenceRecu;
  final String? recuFichierUrl;
  final String commentaireEtudiant;
  final String statut;
  final String motifRefus;
  final String? administrateurNom;
  final String etudiantNom;
  final String etudiantEmail;
  final String etudiantPhone;
  final DateTime createdAt;
  final DateTime? dateTraitement;

  AppTransaction({
    required this.id,
    this.documentId,
    required this.documentTitre,
    this.documentPrix = 0,
    required this.montant,
    required this.devise,
    required this.moyenPaiement,
    required this.referenceKkiapay,
    this.numeroTelephone = '',
    this.referenceRecu = '',
    this.recuFichierUrl,
    this.commentaireEtudiant = '',
    required this.statut,
    this.motifRefus = '',
    this.administrateurNom,
    this.etudiantNom = '',
    this.etudiantEmail = '',
    this.etudiantPhone = '',
    required this.createdAt,
    this.dateTraitement,
  });

  // Rétro-compatibilité
  int? get epreuveId => documentId;
  String get epreuveTitre => documentTitre;
  double get epreuvePrix => documentPrix;

  bool get isValidated => statut == 'PAID' || statut == 'SUCCESS';
  bool get isPending =>
      statut == 'PENDING_VERIFICATION' ||
      statut == 'PAYMENT_SUBMITTED' ||
      statut == 'PENDING';
  bool get isRejected => statut == 'REJECTED' || statut == 'FAILED';

  String? get fullRecuUrl {
    if (recuFichierUrl == null || recuFichierUrl!.trim().isEmpty) return null;
    final url = recuFichierUrl!.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    const base = ApiConstants.baseUrl;
    final origin = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : (base.endsWith('/api/') ? base.substring(0, base.length - 5) : base);
    return '$origin${url.startsWith('/') ? '' : '/'}$url';
  }

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
        id: json['id'] ?? 0,
        documentId: json['document'] ?? json['epreuve'],
        documentTitre: json['document_titre'] ?? json['epreuve_titre'] ?? '',
        documentPrix: double.tryParse('${json['document_prix'] ?? json['epreuve_prix']}') ?? 0,
        montant: double.tryParse('${json['montant']}') ?? 0,
        devise: json['devise'] ?? 'XOF',
        moyenPaiement: json['moyen_paiement'] ?? 'MOBILE_MONEY',
        referenceKkiapay: json['reference_kkiapay'] ?? '',
        numeroTelephone: json['numero_telephone'] ?? '',
        referenceRecu: json['reference_recu'] ?? '',
        recuFichierUrl: json['recu_fichier_url'],
        commentaireEtudiant: json['commentaire_etudiant'] ?? '',
        statut: json['statut'] ?? 'PENDING_VERIFICATION',
        motifRefus: json['motif_refus'] ?? '',
        administrateurNom: json['administrateur_nom'],
        etudiantNom: json['etudiant_nom'] ?? '',
        etudiantEmail: json['etudiant_email'] ?? '',
        etudiantPhone: json['etudiant_phone'] ?? '',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        dateTraitement: json['date_traitement'] != null
            ? DateTime.tryParse(json['date_traitement'])
            : null,
      );
}
