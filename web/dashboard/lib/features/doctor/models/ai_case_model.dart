import 'package:cloud_firestore/cloud_firestore.dart';

class AiCaseModel {
  final String patientId;
  final String screeningId;
  final String patientName;
  final String mediaType;
  final String mediaUrl;
  final String? aiResult;
  final DateTime date; // screenings use "date"
  final String status;
  final String? finalDiagnosis;
  final String? diagnosedBy;
  final String? doctorNotes;
  final Map<String, dynamic>? symptoms;
  final Map<String, dynamic>? aiPrediction;
  final double? aiConfidence; // New field from screenshot

  AiCaseModel({
    required this.patientId,
    required this.screeningId,
    required this.patientName,
    required this.mediaType,
    required this.mediaUrl,
    required this.date,
    required this.status,
    this.finalDiagnosis,
    this.diagnosedBy,
    this.doctorNotes,
    this.symptoms,
    this.aiResult,
    this.aiPrediction,
    this.aiConfidence,
  });

  factory AiCaseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String patientId,
    String patientName,
  ) {
    final data = doc.data() ?? {};

    // Parse symptoms (List in new schema)
    final symptomsList = data['symptoms'] is List ? List<String>.from(data['symptoms']) : <String>[];
    final symptomsMap = {for (var s in symptomsList) s: true};

    // Parse AI prediction (String in Firestore)
    final aiPredString = data['aiPrediction'] as String? ?? 'Pending';
    final aiConfidence = (data['aiConfidence'] as num?)?.toDouble();

    final aiPredictionMap = {
      'prediction': aiPredString,
      'confidence': aiConfidence
    };

    return AiCaseModel(
      patientId: patientId,
      screeningId: data['screeningId'] ?? doc.id,
      patientName: patientName,
      mediaType: data['xrayImage'] != null
          ? 'xray'
          : (data['coughAudioPath'] != null ? 'cough' : 'unknown'),
      mediaUrl: data['xrayImage'] ?? data['coughAudioPath'] ?? '',
      date: (data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(), // 🔑 correct field for screenings
      aiResult: aiPredString,
      aiPrediction: aiPredictionMap,
      aiConfidence: aiConfidence,
      status: data['status'] ?? 'Pending Review',
      finalDiagnosis: data['doctorDiagnosis'],
      diagnosedBy: data['diagnosedBy'],
      doctorNotes: data['doctorNotes'] as String? ?? (data['doctorDiagnosis'] != null
          ? "Diagnosis: ${data['doctorDiagnosis']}"
          : null),
      symptoms: symptomsMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'screeningId': screeningId,
      'patientName': patientName,
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'timestamp': Timestamp.fromDate(date), // 🔑 correct persistence field
      'aiResult': aiResult,
      'aiPrediction': aiPrediction,
      'status': status,
      'finalDiagnosis': finalDiagnosis,
      'diagnosedBy': diagnosedBy,
      'doctorNotes': doctorNotes,
      'symptoms': symptoms,
    };
  }

  AiCaseModel copyWith({
    String? patientId,
    String? screeningId,
    String? patientName,
    String? mediaType,
    String? mediaUrl,
    String? aiResult,
    DateTime? date,
    String? status,
    String? finalDiagnosis,
    String? diagnosedBy,
    String? doctorNotes,
    Map<String, dynamic>? symptoms,
    Map<String, dynamic>? aiPrediction,
  }) {
    return AiCaseModel(
      patientId: patientId ?? this.patientId,
      screeningId: screeningId ?? this.screeningId,
      patientName: patientName ?? this.patientName,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      aiResult: aiResult ?? this.aiResult,
      date: date ?? this.date,
      status: status ?? this.status,
      finalDiagnosis: finalDiagnosis ?? this.finalDiagnosis,
      diagnosedBy: diagnosedBy ?? this.diagnosedBy,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      symptoms: symptoms ?? this.symptoms,
      aiPrediction: aiPrediction ?? this.aiPrediction,
    );
  }
}
