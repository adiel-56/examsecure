class PaymentConfig {
  final int id;
  final String numeroMoov;
  final String numeroMtn;
  final String numeroCeltis;
  final String beneficiaryName;
  final String instructions;
  final bool isActive;
  final DateTime? updatedAt;

  PaymentConfig({
    required this.id,
    this.numeroMoov = '',
    this.numeroMtn = '',
    this.numeroCeltis = '',
    required this.beneficiaryName,
    required this.instructions,
    this.isActive = true,
    this.updatedAt,
  });

  factory PaymentConfig.fromJson(Map<String, dynamic> json) => PaymentConfig(
        id: json['id'] ?? 1,
        numeroMoov: json['numero_moov'] ?? '',
        numeroMtn: json['numero_mtn'] ?? '',
        numeroCeltis: json['numero_celtis'] ?? '',
        beneficiaryName: json['beneficiary_name'] ?? 'Administration ExamSecure',
        instructions: json['instructions'] ??
            'Pour accéder à ce document, veuillez envoyer le montant indiqué au numéro Mobile Money de l\'administration.',
        isActive: json['is_active'] ?? true,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'numero_moov': numeroMoov,
        'numero_mtn': numeroMtn,
        'numero_celtis': numeroCeltis,
        'beneficiary_name': beneficiaryName,
        'instructions': instructions,
        'is_active': isActive,
      };
}
