import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationModel {
  final String recommendationId;
  final String medicalAdvice;
  final String lifestyleAdvice;
  final String addedBy;   
  final String approvedBy;
  final DateTime createdAt;

  RecommendationModel({
    required this.recommendationId,
    required this.medicalAdvice,
    required this.lifestyleAdvice,
    required this.addedBy,
    required this.approvedBy,
    required this.createdAt,
  });

  factory RecommendationModel.fromMap(Map<String, dynamic> map) {
    return RecommendationModel(
      recommendationId: map['recommendationId'] ?? '',
      medicalAdvice: map['medicalAdvice'] ?? '',
      lifestyleAdvice: map['lifestyleAdvice'] ?? '',
      addedBy: map['addedBy'] ?? '',
      approvedBy: map['approvedBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recommendationId': recommendationId,
      'medicalAdvice': medicalAdvice,
      'lifestyleAdvice': lifestyleAdvice,
      'addedBy': addedBy,
      'approvedBy': approvedBy,
      'createdAt': createdAt,
    };
  }
}
