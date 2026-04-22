import 'package:cloud_firestore/cloud_firestore.dart';

class Referral {
  final String id;
  final String patientId;
  final String patientName;
  final String chwId;
  final String referralStatus; // routine / urgent / emergency
  final String status; // open / pending / seen / completed
  final DateTime? timestamp;

  Referral({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.chwId,
    required this.referralStatus,
    required this.status,
    this.timestamp,
  });

  factory Referral.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Referral(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown',
      chwId: data['chwId'] ?? '',
      referralStatus: data['referralStatus'] ?? 'routine',
      status: data['status'] ?? 'open',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
