enum UserRole { teacher, student }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImage;
  final String? department;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
    this.department,
  });
}
