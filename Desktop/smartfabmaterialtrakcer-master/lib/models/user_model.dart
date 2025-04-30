import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  operator
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${data['role'] ?? 'operator'}',
        orElse: () => UserRole.operator,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
    };
  }

  // Convenience method to get role as a readable string
  String get roleDisplay {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.operator:
        return 'Operator';
    }
  }
}
