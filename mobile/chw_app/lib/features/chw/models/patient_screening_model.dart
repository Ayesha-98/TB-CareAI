import 'package:cloud_firestore/cloud_firestore.dart';

class Screening {
  String? id;
  String patientId;
  String patientName;
  String chwId;
  List<String> symptoms;
  String coughAudioPath;
  dynamic aiPrediction; // Changed from String to dynamic to handle both String and Map
  Map<String, String> media;
  String status; // New status field - replaces followUpNeeded, followUpStatus, referred
  Timestamp timestamp;
  Timestamp? updatedAt;

  // 🔹 ADDED: Doctor assignment fields
  String? assignedDoctorId;
  String? assignedDoctorName;

  // 🔹 NEW AI Fields
  double? aiConfidence;
  Map<String, dynamic>? aiRawData;
  String? message;
  Map<String, dynamic>? prediction;
  bool? success;

  var result;

  Screening({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.chwId,
    required this.symptoms,
    required this.coughAudioPath,
    required this.aiPrediction,
    required this.media,
    required this.status, // New required field
    required this.timestamp,
    this.updatedAt,
    // 🔹 ADDED: Doctor assignment parameters
    this.assignedDoctorId,
    this.assignedDoctorName,
    // 🔹 NEW AI Fields
    this.aiConfidence,
    this.aiRawData,
    this.message,
    this.prediction,
    this.success,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'chwId': chwId,
      'symptoms': symptoms.isEmpty ? ["No symptoms"] : symptoms,
      'coughAudioPath': coughAudioPath,
      'aiPrediction': aiPrediction,
      'media': media,
      'status': status, // New status field
      'timestamp': timestamp,
      'updatedAt': updatedAt,
      // 🔹 ADDED: Doctor assignment fields
      'assignedDoctorId': assignedDoctorId,
      'assignedDoctorName': assignedDoctorName,
      // 🔹 NEW AI Fields
      'aiConfidence': aiConfidence,
      'aiRawData': aiRawData,
      'message': message,
      'prediction': prediction,
      'success': success,
    };
  }

  factory Screening.fromMap(Map<String, dynamic> data) {
    // defensively copy map to avoid runtime casting surprises
    final map = Map<String, dynamic>.from(data);

    // Accept id from 'id' or 'screeningId'
    final idVal = (map['id'] ?? map['screeningId'] ?? '').toString();

    // Normalize timestamp: if it's a Timestamp keep it; if DateTime convert to Timestamp
    Timestamp ts;
    final rawTs = map['timestamp'];
    if (rawTs is Timestamp) {
      ts = rawTs;
    } else if (rawTs is DateTime) {
      ts = Timestamp.fromDate(rawTs);
    } else {
      ts = Timestamp.now();
    }

    // Parse symptoms - handle both List<String> and List<dynamic>
    List<String> symptomsList = [];
    final rawSymptoms = map['symptoms'];
    if (rawSymptoms is List) {
      for (var item in rawSymptoms) {
        if (item is String) {
          symptomsList.add(item);
        } else {
          symptomsList.add(item.toString());
        }
      }
    }

    return Screening(
      id: idVal.isEmpty ? null : idVal,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? 'Unknown',
      chwId: map['chwId'] ?? '',
      symptoms: symptomsList,
      coughAudioPath: map['coughAudioPath'] ?? map['coughAudio'] ?? '',
      aiPrediction: map['aiPrediction'] != null
          ? (map['aiPrediction'] is Map
          ? Map<String, dynamic>.from(map['aiPrediction'])
          : map['aiPrediction'])
          : {},
      media: Map<String, String>.from(map['media'] ?? {'coughUrl': '', 'xrayUrl': ''}),
      status: map['status'] ?? 'pending',
      timestamp: ts,
      updatedAt: map['updatedAt'],
      // 🔹 ADDED: Doctor assignment fields
      assignedDoctorId: map['assignedDoctorId'],
      assignedDoctorName: map['assignedDoctorName'],
      // 🔹 NEW AI Fields
      aiConfidence: (map['aiConfidence'] as num?)?.toDouble(),
      aiRawData: map['aiRawData'] as Map<String, dynamic>?,
      message: map['message'] as String?,
      prediction: map['prediction'] as Map<String, dynamic>?,
      success: map['success'] as bool?,
    );
  }

  /// 🆕 Added copyWith
  Screening copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? chwId,
    List<String>? symptoms,
    String? coughAudioPath,
    dynamic aiPrediction,
    Map<String, String>? media,
    String? status,
    Timestamp? timestamp,
    Timestamp? updatedAt,
    String? assignedDoctorId,
    String? assignedDoctorName,
    double? aiConfidence,
    Map<String, dynamic>? aiRawData,
    String? message,
    Map<String, dynamic>? prediction,
    bool? success,
  }) {
    return Screening(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      chwId: chwId ?? this.chwId,
      symptoms: symptoms ?? this.symptoms,
      coughAudioPath: coughAudioPath ?? this.coughAudioPath,
      aiPrediction: aiPrediction ?? this.aiPrediction,
      media: media ?? this.media,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
      assignedDoctorName: assignedDoctorName ?? this.assignedDoctorName,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiRawData: aiRawData ?? this.aiRawData,
      message: message ?? this.message,
      prediction: prediction ?? this.prediction,
      success: success ?? this.success,
    );
  }

  /// 🔹 HELPER GETTERS for AI Analysis - FIXED VERSION

  // Get TB probability (converted from percentage to decimal)
  double get tbProbability {
    if (prediction != null && prediction!['tb_probability'] != null) {
      // Convert from percentage (100) to decimal (1.0)
      final tbProb = prediction!['tb_probability'] as num;
      return tbProb.toDouble() / 100.0; // ← CRITICAL: DIVIDE BY 100
    }
    // Fallback: try to get from aiPrediction map
    if (aiPrediction is Map && (aiPrediction as Map).containsKey('TB')) {
      try {
        final tbValue = (aiPrediction as Map)['TB'];
        if (tbValue is num) {
          return tbValue.toDouble() / 100.0; // ← ALSO DIVIDE BY 100
        }
        return double.parse(tbValue.toString()) / 100.0;
      } catch (e) {
        return 0.0;
      }
    }
    // Fallback 2: Use aiConfidence if diagnosis is TB
    final diagnosis = aiDiagnosis.toLowerCase();
    if ((diagnosis == 'tb' || diagnosis == 'tuberculosis') && aiConfidence != null) {
      return aiConfidence! / 100.0;
    }
    return 0.0;
  }

  // Get normal probability (converted from percentage to decimal)
  double get normalProbability {
    if (prediction != null && prediction!['normal_probability'] != null) {
      // Convert from percentage (0) to decimal (0.0)
      final normalProb = prediction!['normal_probability'] as num;
      return normalProb.toDouble() / 100.0; // ← CRITICAL: DIVIDE BY 100
    }
    // Fallback: try to get from aiPrediction map
    if (aiPrediction is Map && (aiPrediction as Map).containsKey('Normal')) {
      try {
        final normalValue = (aiPrediction as Map)['Normal'];
        if (normalValue is num) {
          return normalValue.toDouble() / 100.0; // ← ALSO DIVIDE BY 100
        }
        return double.parse(normalValue.toString()) / 100.0;
      } catch (e) {
        return 1.0 - tbProbability;
      }
    }
    // Fallback 2: Use aiConfidence if diagnosis is Normal
    final diagnosis = aiDiagnosis.toLowerCase();
    if (diagnosis == 'normal' && aiConfidence != null) {
      return aiConfidence! / 100.0;
    }
    return 1.0 - tbProbability;
  }

  // Get AI diagnosis (Normal or TB)
  String get aiDiagnosis {
    if (prediction != null && prediction!['class'] != null) {
      return prediction!['class'].toString();
    }
    // Check aiPrediction string
    if (aiPrediction is String) {
      final str = aiPrediction as String;
      if (str.toLowerCase().contains('tb') || str.toLowerCase().contains('tuberculosis')) {
        return 'Tuberculosis';
      }
      return 'Normal';
    }
    // Fallback: check which probability is higher
    if (tbProbability > 0.5) {
      return 'Tuberculosis';
    } else {
      return 'Normal';
    }
  }

  // Check if screening is flagged (TB probability > 50%)
  bool get isFlagged => tbProbability > 0.5;

  // Get AI confidence (already in percentage, no division needed)
  double get aiConfidencePercent {
    if (aiConfidence != null) {
      return aiConfidence!; // Already in percentage (e.g., 100)
    }
    if (prediction != null && prediction!['confidence'] != null) {
      return (prediction!['confidence'] as num).toDouble(); // Already in percentage
    }
    return 0.0;
  }

  // Get AI result message
  String get aiMessage {
    if (message != null && message!.isNotEmpty) {
      return message!;
    }
    // Generate message from diagnosis and confidence
    final confidence = aiConfidencePercent;
    final diagnosis = aiDiagnosis;
    return 'Diagnosis: $diagnosis (${confidence.toStringAsFixed(2)}%)';
  }

  // Helper to check if screening can be sent to doctor
  bool get canSendToDoctor {
    return status == 'ai_completed' || status == 'pending_referral';
  }

  // Helper to check if already sent to doctor
  bool get isSentToDoctor {
    return status == 'sent_to_doctor';
  }

  @override
  String toString() {
    return 'Screening(id: $id, patient: $patientName, status: $status, diagnosis: $aiDiagnosis, TB: ${(tbProbability * 100).toStringAsFixed(1)}%, Normal: ${(normalProbability * 100).toStringAsFixed(1)}%)';
  }
}