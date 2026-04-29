import 'package:cloud_firestore/cloud_firestore.dart';

class Screening {
  final String id;
  final String patientId;
  final String patientName;
  final String chwId;
  final bool followUpNeeded;
  final String followUpStatus;
  final Map<String, dynamic> media;
  final List<String> symptoms;
  final bool referred;
  final String referralStatus;
  final dynamic aiPrediction; // <-- change here
  final DateTime? timestamp;

  Screening({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.chwId,
    required this.followUpNeeded,
    required this.followUpStatus,
    required this.media,
    required this.symptoms,
    required this.referred,
    required this.referralStatus,
    required this.aiPrediction,
    this.timestamp,
  });

  factory Screening.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Screening(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown',
      chwId: data['chwId'] ?? '',
      followUpNeeded: data['followUpNeeded'] ?? false,
      followUpStatus: data['followUpStatus'] ?? 'pending',
      media: Map<String, dynamic>.from(data['media'] ?? {}),
      symptoms: List<String>.from(data['symptoms'] ?? []),
      referred: data['referred'] ?? false,
      referralStatus: data['referralStatus'] ?? '',
      aiPrediction: data['aiPrediction'], // dynamic, can be Map or String
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
