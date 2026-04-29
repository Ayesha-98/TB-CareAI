import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String photoUrl;
  final String diagnosisStatus;
  final DateTime? createdAt;

  PatientModel({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.photoUrl,
    required this.diagnosisStatus,
    this.createdAt,
  });

  factory PatientModel.fromMap(Map<String, dynamic> data) {
    return PatientModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      age: data['age'] is int
          ? data['age']
          : int.tryParse(data['age']?.toString() ?? '0') ?? 0,
      gender: data['gender'] ?? 'N/A',
      photoUrl: data['photoUrl'] ?? '',
      diagnosisStatus: data['diagnosisStatus'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'age': age,
      'gender': gender,
      'photoUrl': photoUrl,
      'diagnosisStatus': diagnosisStatus,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  PatientModel copyWith({
    String? uid,
    String? name,
    int? age,
    String? gender,
    String? photoUrl,
    String? diagnosisStatus,
    DateTime? createdAt,
  }) {
    return PatientModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      diagnosisStatus: diagnosisStatus ?? this.diagnosisStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
