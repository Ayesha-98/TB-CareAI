import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: (data['role'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
    };
  }
}
