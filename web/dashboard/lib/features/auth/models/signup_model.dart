import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool verified;
  final String status;
  final bool flagged;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.verified = false,
    this.status = "Active",
    this.flagged = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "role": role,
      "verified": verified,
      "status": status,
      "flagged": flagged,
      "createdAt": createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(), // 🚨 CRITICAL: Add this line
      "authProvider": "email", // 🚨 CRITICAL: Add this field
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    Timestamp? timestamp = map["createdAt"] as Timestamp?;

    return UserModel(
      uid: uid,
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      role: map["role"] ?? "Patient",
      verified: map["verified"] ?? false,
      status: map["status"] ?? "Active",
      flagged: map["flagged"] ?? false,
      createdAt: timestamp?.toDate(),
    );
  }
}