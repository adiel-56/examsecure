class AppNotification {
  final int id;
  final String titre;
  final String message;
  final String type;
  final bool lu;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.lu,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        titre: json['titre'] ?? '',
        message: json['message'] ?? '',
        type: json['type'] ?? 'INFO',
        lu: json['lu'] ?? false,
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}
