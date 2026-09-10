enum UserRole { student, admin }

UserRole roleFromString(String value) => value == 'ADMIN' ? UserRole.admin : UserRole.student;

class AppUser {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final int? filiereId;

  AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.filiereId,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        firstName: json['first_name'] ?? '',
        lastName: json['last_name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        role: roleFromString(json['role'] ?? 'STUDENT'),
        filiereId: json['filiere'],
      );
}
