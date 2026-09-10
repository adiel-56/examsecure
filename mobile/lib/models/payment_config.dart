class PaymentConfig {
  final int id;
  final String momoNumber;
  final String beneficiaryName;
  final String instructions;
  final bool isActive;
  final DateTime? updatedAt;

  PaymentConfig({
    required this.id,
    required this.momoNumber,
    required this.beneficiaryName,
    required this.instructions,
    this.isActive = true,
    this.updatedAt,
  });

  factory PaymentConfig.fromJson(Map<String, dynamic> json) => PaymentConfig(
        id: json['id'] ?? 1,
        momoNumber: json['momo_number'] ?? '+229 97 00 00 00',
        beneficiaryName: json['beneficiary_name'] ?? 'Administration ExamSecure',
        instructions: json['instructions'] ??
            'Pour accéder à ce document, veuillez envoyer le montant indiqué au numéro Mobile Money de l\'administration.',
        isActive: json['is_active'] ?? true,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'momo_number': momoNumber,
        'beneficiary_name': beneficiaryName,
        'instructions': instructions,
        'is_active': isActive,
      };
}
