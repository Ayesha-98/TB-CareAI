import 'package:cloud_firestore/cloud_firestore.dart';

class RecentCase {
  final String patientId;
  final String patientName;
  final String diagnosis;
  final DateTime date;
  final String icon;

  RecentCase({
    required this.patientId,
    required this.patientName,
    required this.diagnosis,
    required this.date,
    required this.icon,
  });

  factory RecentCase.fromFirestore(
    Map<String, dynamic> patientData,
    Map<String, dynamic> screeningData,
    String patientId,
    String screeningId,
  ) {
    return RecentCase(
      patientId: patientId,
      patientName: patientData['name'] ?? '',
      diagnosis: screeningData['doctorDiagnosis'] ?? 'Pending Review',
      date: (screeningData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      icon: "assets/icons/user.svg",
    );
  }
}
