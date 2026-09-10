class Matiere {
  final int id;
  final String nom;
  final int filiereId;
  final String filiereNom;

  Matiere({required this.id, required this.nom, required this.filiereId, required this.filiereNom});

  factory Matiere.fromJson(Map<String, dynamic> json) => Matiere(
        id: json['id'],
        nom: json['nom'] ?? '',
        filiereId: json['filiere'],
        filiereNom: json['filiere_nom'] ?? '',
      );
}
