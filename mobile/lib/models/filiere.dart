class Filiere {
  final int id;
  final String nom;
  final String description;
  final int matieresCount;

  Filiere({required this.id, required this.nom, required this.description, this.matieresCount = 0});

  factory Filiere.fromJson(Map<String, dynamic> json) => Filiere(
        id: json['id'],
        nom: json['nom'] ?? '',
        description: json['description'] ?? '',
        matieresCount: json['matieres_count'] ?? 0,
      );
}
