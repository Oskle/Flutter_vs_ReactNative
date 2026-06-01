import 'package:coeval/domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.profileImage,
    super.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: _roleFromString(json['role'] as String? ?? 'student'),
      profileImage: json['profileImage'] as String?,
      department: json['department'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'profileImage': profileImage,
      'department': department,
    };
  }

  static UserRole _roleFromString(String roleString) {
    return roleString.toLowerCase() == 'teacher'
        ? UserRole.teacher
        : UserRole.student;
  }
}
