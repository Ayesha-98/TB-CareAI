import 'package:cloud_firestore/cloud_firestore.dart';

class DiagnosisModel {
  final String diagnosisId;
  final String doctorId;
  final String status;
  final String? notes;
  final List<String> requestedTests;
  final bool reviewable;
  final bool verdictGiven;
  final DateTime createdAt;

  DiagnosisModel({
    required this.diagnosisId,
    required this.doctorId,
    required this.status,
    this.notes,
    required this.requestedTests,
    required this.reviewable,
    required this.verdictGiven,
    required this.createdAt,
  });

  factory DiagnosisModel.fromMap(Map<String, dynamic> data, String id) {
    return DiagnosisModel(
      diagnosisId: data['diagnosisId'] ?? id,
      doctorId: data['doctorId'] ?? '',
      status: data['status'] ?? '',
      notes: data['notes'],
      requestedTests: List<String>.from(data['requestedTests'] ?? []),
      reviewable: data['reviewable'] ?? false,
      verdictGiven: data['verdictGiven'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'diagnosisId': diagnosisId,
      'doctorId': doctorId,
      'status': status,
      'notes': notes,
      'requestedTests': requestedTests,
      'reviewable': reviewable,
      'verdictGiven': verdictGiven,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  DiagnosisModel copyWith({
    String? diagnosisId,
    String? doctorId,
    String? status,
    String? notes,
    List<String>? requestedTests,
    bool? reviewable,
    bool? verdictGiven,
    DateTime? createdAt,
  }) {
    return DiagnosisModel(
      diagnosisId: diagnosisId ?? this.diagnosisId,
      doctorId: doctorId ?? this.doctorId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      requestedTests: requestedTests ?? this.requestedTests,
      reviewable: reviewable ?? this.reviewable,
      verdictGiven: verdictGiven ?? this.verdictGiven,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
