import 'package:cloud_firestore/cloud_firestore.dart';

class LabTestModel {
  final String labTestId;
  final String testName;
  final String? fileUrl;
  final String status;
  final String? comments;
  final DateTime requestedAt;
  final DateTime? uploadedAt;

  LabTestModel({
    required this.labTestId,
    required this.testName,
    this.fileUrl,
    required this.status,
    this.comments,
    required this.requestedAt,
    this.uploadedAt,
  });

  factory LabTestModel.fromMap(Map<String, dynamic> data, String id) {
    return LabTestModel(
      labTestId: data['labTestId'] ?? id,
      testName: data['testName'] ?? '',
      fileUrl: data['fileUrl'],
      status: data['status'] ?? 'Pending',
      comments: data['comments'],
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'labTestId': labTestId,
      'testName': testName,
      'fileUrl': fileUrl,
      'status': status,
      'comments': comments,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'uploadedAt': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : null,
    };
  }

  LabTestModel copyWith({
    String? labTestId,
    String? testName,
    String? fileUrl,
    String? status,
    String? comments,
    DateTime? requestedAt,
    DateTime? uploadedAt,
  }) {
    return LabTestModel(
      labTestId: labTestId ?? this.labTestId,
      testName: testName ?? this.testName,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      requestedAt: requestedAt ?? this.requestedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
