import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String name;

  Patient({required this.id, required this.name});

  factory Patient.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Patient(
      id: doc.id,
      name: data['name'] ?? 'Unnamed',
    );
  }
}

class Screening {
  final String id;
  final List<String> symptoms;
  final DateTime? timestamp;
  final Map<String, String> aiPrediction;
  final String coughAudioPath;

  Screening({
    required this.id,
    required this.symptoms,
    required this.timestamp,
    required this.aiPrediction,
    required this.coughAudioPath,
  });

  factory Screening.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Handle symptoms as Map or List
    List<String> symptomsList = [];
    if (data['symptoms'] is Map) {
      symptomsList = (data['symptoms'] as Map<String, dynamic>).keys.toList();
    } else if (data['symptoms'] is List) {
      symptomsList = List<String>.from(data['symptoms']);
    }

    // Safe aiPrediction parsing
    final Map<String, dynamic> rawAi = data['aiPrediction'] ?? {};
    final aiPred = rawAi.map((k, v) => MapEntry(k, v.toString()));

    // Cough path
    String coughPath = data['coughAudioPath'] ?? '';
    if ((coughPath.isEmpty) && (data['media'] != null)) {
      coughPath = data['media']['coughUrl'] ?? '';
    }

    // Timestamp
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

    return Screening(
      id: doc.id,
      symptoms: symptomsList,
      timestamp: timestamp,
      aiPrediction: aiPred,
      coughAudioPath: coughPath,
    );
  }
}
