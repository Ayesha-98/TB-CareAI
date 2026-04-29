import 'package:flutter/material.dart';

class DoctorStat {
  final String label;
  final int value;
  final String icon;
  final Color color;

  DoctorStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  factory DoctorStat.fromFirestore(
    String label,
    int value,
    String icon,
    Color color,
  ) {
    return DoctorStat(label: label, value: value, icon: icon, color: color);
  }
}

List<DoctorStat> buildDoctorStats(Map<String, dynamic> data) {
  return [
    DoctorStat.fromFirestore(
      "Confirmed TB",
      data['confirmedTBCount'] ?? 0,
      "assets/icons/check-shield.svg",
      const Color(0xFFEE2727),
    ),
    DoctorStat.fromFirestore(
      "Diagnoses",
      data['totalDiagnosisMade'] ?? 0,
      "assets/icons/clipboard.svg",
      const Color(0xFF26E5FF),
    ),
    DoctorStat.fromFirestore(
      "Patients Reviewed",
      data['totalPatientsReviewed'] ?? 0,
      "assets/icons/user.svg",
      const Color(0xFF007EE5),
    ),
    DoctorStat.fromFirestore(
      "Recommendations",
      data['totalRecommendationsGiven'] ?? 0,
      "assets/icons/brain.svg",
      const Color(0xFFFFCF26),
    ),
    DoctorStat.fromFirestore(
      "Tests Requested",
      data['totalTestsRequested'] ?? 0,
      "assets/icons/medical.svg",
      const Color(0xFF8BC34A),
    ),
  ];
}
