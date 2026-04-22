class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool verified;
  final String status;
  final bool flagged;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.verified = false,
    this.status = "Active",
    this.flagged = false,
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
      "createdAt": DateTime.now(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      role: map["role"] ?? "Patient",
      verified: map["verified"] ?? false,
      status: map["status"] ?? "Active",
      flagged: map["flagged"] ?? false,
    );
  }
}
