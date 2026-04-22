import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tbcare_main/core/app_constants.dart';

class DoctorNotesScreen extends StatelessWidget {
  final String patientId;
  final String screeningId;
  final String patientName;
  static const infoColor = primaryColor;

  const DoctorNotesScreen({
    super.key,
    required this.patientId,
    required this.screeningId,
    required this.patientName,
  });

  Future<Map<String, dynamic>> _fetchNotes() async {
    // ✅ Safety check for missing IDs
    if (patientId.isEmpty || screeningId.isEmpty) {
      throw Exception(
          "Invalid document path — patientId or screeningId is missing.\n\n"
              "patientId: $patientId\nscreeningId: $screeningId");
    }

    final firestore = FirebaseFirestore.instance;
    final screeningRef = firestore
        .collection("patients")
        .doc(patientId)
        .collection("screenings")
        .doc(screeningId);

    final docSnap = await screeningRef.get();

    final diagnosisSnap = await screeningRef.collection("diagnosis").get();
    final recSnap = await screeningRef.collection("recommendations").get();

    // 🔥 MODIFIED: Get lab tests from the labTests subcollection
    // This is kept as fallback for existing data
    final labSnap = await screeningRef.collection("labTests").get();

    // 🔥 NEW: Extract requested tests from diagnosis documents
    final List<Map<String, dynamic>> requestedTestsFromDiagnosis = [];

    for (final diagnosisDoc in diagnosisSnap.docs) {
      final diagnosisData = diagnosisDoc.data();
      final requestedTests = diagnosisData['requestedTests'];

      if (requestedTests is List && requestedTests.isNotEmpty) {
        // Get doctor info
        final doctorId = diagnosisData['doctorId']?.toString();
        String doctorName = 'Doctor';

        if (doctorId != null && doctorId.isNotEmpty) {
          try {
            final doctorDoc = await firestore.collection('doctors').doc(doctorId).get();
            if (doctorDoc.exists) {
              doctorName = doctorDoc.data()?['name']?.toString() ?? 'Doctor';
            } else {
              final userDoc = await firestore.collection('users').doc(doctorId).get();
              if (userDoc.exists) {
                doctorName = userDoc.data()?['name']?.toString() ?? 'Doctor';
              }
            }
          } catch (e) {
            print('Error fetching doctor name for lab tests: $e');
          }
        }

        // Create lab test entries for each requested test
        for (final test in requestedTests) {
          final testName = test.toString();
          if (testName.isNotEmpty) {
            requestedTestsFromDiagnosis.add({
              'Test Name': testName,
              'Prescribed By': doctorName,
              'Status': 'Prescribed',
              'Type': 'Doctor Requested',
              'Requested At': diagnosisData['createdAt'] ?? FieldValue.serverTimestamp(),
            });
          }
        }
      }
    }

    // 🔥 NEW: Combine lab tests from both sources
    final List<Map<String, dynamic>> allLabTests = [];

    // Add doctor-requested tests first
    allLabTests.addAll(requestedTestsFromDiagnosis);

    // Add uploaded lab tests from labTests subcollection
    allLabTests.addAll(labSnap.docs.map((d) {
      final data = d.data();
      return {
        'Test Name': data['testName'] ?? 'Lab Test',
        'Status': data['status'] ?? 'Uploaded',
        'File URL': data['fileUrl'] ?? '',
        'Comments': data['comments'] ?? '',
        'Uploaded At': data['uploadedAt'] ?? data['requestedAt'],
        'Type': 'Uploaded Result',
      };
    }).toList());

    // 🔥 ADDED: Try to get doctor's name from multiple possible fields
    final screeningData = docSnap.data() ?? {};
    String? doctorName;

    // Check multiple possible fields for doctor's name
    if (screeningData['diagnosedBy'] != null && screeningData['diagnosedBy'].toString().isNotEmpty) {
      doctorName = screeningData['diagnosedBy'].toString();
    } else if (screeningData['assignedDoctorName'] != null && screeningData['assignedDoctorName'].toString().isNotEmpty) {
      doctorName = screeningData['assignedDoctorName'].toString();
    } else if (screeningData['doctorName'] != null && screeningData['doctorName'].toString().isNotEmpty) {
      doctorName = screeningData['doctorName'].toString();
    } else {
      // If no doctor name in screening, check the assigned doctor info
      try {
        // Check if there's an assignedDoctorId and fetch doctor details
        final doctorId = screeningData['assignedDoctorId']?.toString();
        if (doctorId != null && doctorId.isNotEmpty) {
          final doctorDoc = await firestore.collection('doctors').doc(doctorId).get();
          if (doctorDoc.exists) {
            doctorName = doctorDoc.data()?['name']?.toString() ?? 'Dr. Unknown';
          } else {
            // Try users collection
            final userDoc = await firestore.collection('users').doc(doctorId).get();
            if (userDoc.exists) {
              doctorName = userDoc.data()?['name']?.toString() ?? 'Dr. Unknown';
            }
          }
        }
      } catch (e) {
        print('Error fetching doctor name: $e');
      }
    }

    // Update screening data with found doctor name
    final updatedScreeningData = Map<String, dynamic>.from(screeningData);
    if (doctorName != null && updatedScreeningData['diagnosedBy'] == null) {
      updatedScreeningData['diagnosedBy'] = doctorName;
    }

    return {
      "screening": updatedScreeningData,
      "diagnosis": diagnosisSnap.docs.map((d) => d.data()).toList(),
      "recommendations": recSnap.docs.map((d) => d.data()).toList(),
      "labTests": allLabTests, // 🔥 MODIFIED: Now includes requested tests
      "doctorName": doctorName,
    };
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notes, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(Map<String, dynamic> map) {
    if (map.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            "No data available",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: map.entries.map((e) {
          final value = e.value?.toString() ?? "";
          final isUrl = value.startsWith("http");

          // Special formatting for doctor's name
          final bool isDoctorField = e.key.toLowerCase().contains('doctor') ||
              e.key.toLowerCase().contains('diagnosed');
          final String displayValue = value.isEmpty ? 'Not set' : value;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: e.key == map.entries.last.key
                    ? BorderSide.none
                    : BorderSide(color: Colors.grey.shade100),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isUrl
                        ? successColor.withOpacity(0.1)
                        : (isDoctorField ? infoColor.withOpacity(0.1) : primaryColor.withOpacity(0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUrl ? Icons.link :
                    (isDoctorField ? Icons.person : Icons.label_important_outlined),
                    color: isUrl ? successColor :
                    (isDoctorField ? infoColor : primaryColor),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUrl ? "File Uploaded" : displayValue,
                        style: TextStyle(
                          color: isUrl ? successColor :
                          (isDoctorField && value.isNotEmpty ? infoColor : Colors.grey.shade700),
                          fontSize: 14,
                          fontWeight: (isUrl || isDoctorField) ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListCards(List<Map<String, dynamic>> items, {bool isLabTests = false}) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            "No records found",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        // 🔥 Filter out doctorId and diagnosisId from display
        final displayItems = Map<String, dynamic>.from(item)
          ..removeWhere((key, value) =>
          key.toLowerCase() == 'doctorid' ||
              key.toLowerCase() == 'diagnosisid' ||
              key.toLowerCase() == 'doctor_id' ||
              key.toLowerCase() == 'diagnosis_id');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: displayItems.entries.map((e) {
              final value = e.value;
              final isUrl = value is String && value.startsWith("http");

              // Format the value for display
              String displayValue = _formatValueForDisplay(e.key, value);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: e.key == displayItems.entries.last.key
                        ? BorderSide.none
                        : BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isUrl
                            ? successColor.withOpacity(0.1)
                            : accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUrl ? Icons.cloud_done : Icons.arrow_right_rounded,
                        color: isUrl ? successColor : accentColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Format the key for display (convert camelCase to Title Case)
                          Text(
                            _formatKeyForDisplay(e.key),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: secondaryColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUrl ? "File Uploaded" : displayValue,
                            style: TextStyle(
                              color: isUrl ? successColor : Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: isUrl ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // 🔥 NEW: Format key for better display (convert camelCase to Title Case)
  String _formatKeyForDisplay(String key) {
    // Replace underscores with spaces
    String formatted = key.replaceAll('_', ' ');

    // Convert camelCase to Title Case with spaces
    formatted = formatted.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
          (Match m) => '${m[1]} ${m[2]}',
    );

    // Capitalize first letter of each word
    return formatted.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // 🔥 UPDATED: Better value formatting
  String _formatValueForDisplay(String key, dynamic value) {
    if (value == null) return 'Not set';

    // Handle Timestamp objects
    if (value is Timestamp) {
      return _formatFirestoreTimestamp(value);
    }

    // Handle DateTime objects
    if (value is DateTime) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(value);
    }

    // Handle String values
    if (value is String) {
      // Check if it's a timestamp string representation
      if (value.contains('Timestamp(seconds=') && value.contains('nanoseconds=')) {
        return _formatTimestampString(value);
      }

      // Check if it's a date string
      if (value.contains('-') && value.contains(':')) {
        final date = DateTime.tryParse(value);
        if (date != null) {
          return DateFormat('dd MMM yyyy, hh:mm a').format(date);
        }
      }

      // Return the string as-is
      return value.isEmpty ? 'Not set' : value;
    }

    // Handle lists
    if (value is List) {
      if (value.isEmpty) return 'None';
      return value.map((item) => item.toString()).join(', ');
    }

    // Handle other types
    return value.toString();
  }

  // 🔥 NEW: Format Firestore Timestamp to readable date
  String _formatFirestoreTimestamp(Timestamp timestamp) {
    try {
      final date = timestamp.toDate();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      print('Error formatting Timestamp: $e');
      return 'Invalid date';
    }
  }

  // 🔥 UPDATED: Better timestamp string parsing
  String _formatTimestampString(String timestamp) {
    try {
      // Handle Firestore Timestamp string format: "Timestamp(seconds=1770045, nanoseconds=0)"
      final match = RegExp(r'Timestamp\(seconds=(\d+),\s*nanoseconds=(\d+)\)').firstMatch(timestamp);
      if (match != null) {
        final seconds = int.tryParse(match.group(1) ?? '0') ?? 0;
        final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        return DateFormat('dd MMM yyyy, hh:mm a').format(date);
      }

      // Handle other timestamp formats
      final epoch = int.tryParse(timestamp);
      if (epoch != null) {
        if (timestamp.length == 10) { // seconds
          final date = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
          return DateFormat('dd MMM yyyy, hh:mm a').format(date);
        } else if (timestamp.length == 13) { // milliseconds
          final date = DateTime.fromMillisecondsSinceEpoch(epoch);
          return DateFormat('dd MMM yyyy, hh:mm a').format(date);
        }
      }

      return timestamp; // Return original if can't parse
    } catch (e) {
      print('Error formatting timestamp string: $e');
      return timestamp;
    }
  }

  Widget _buildAiPredictionCard(Map<String, dynamic> screening) {
    final prediction = screening['prediction'] is Map ? screening['prediction'] as Map<String, dynamic> : {};
    final aiPrediction = screening['aiPrediction'] is Map ? screening['aiPrediction'] as Map<String, dynamic> : {};
    final aiConfidence = screening['aiConfidence']?.toString() ?? '0';
    final aiMessage = screening['message']?.toString() ?? 'No AI analysis message';
    final success = screening['success'] ?? false;

    // Determine AI result
    String aiResult = "Pending Analysis";
    Color resultColor = warningColor;
    IconData resultIcon = Icons.schedule;

    if (prediction.isNotEmpty) {
      final aiClass = prediction['class']?.toString() ?? 'Unknown';
      final confidence = (prediction['confidence'] as num?)?.toDouble() ?? 0.0;

      if (aiClass.toLowerCase() == 'normal') {
        aiResult = "Normal";
        resultColor = successColor;
        resultIcon = Icons.check_circle;
      } else if (aiClass.toLowerCase() == 'tb') {
        aiResult = "TB Detected";
        resultColor = errorColor;
        resultIcon = Icons.warning;
      } else {
        aiResult = aiClass;
        resultColor = warningColor;
        resultIcon = Icons.help;
      }
    } else if (aiPrediction.isNotEmpty) {
      final tb = double.tryParse(aiPrediction['TB']?.toString() ?? '0') ?? 0;
      final normal = double.tryParse(aiPrediction['Normal']?.toString() ?? '0') ?? 0;

      if (tb > normal) {
        aiResult = "TB Detected";
        resultColor = errorColor;
        resultIcon = Icons.warning;
      } else if (normal > tb) {
        aiResult = "Normal";
        resultColor = successColor;
        resultIcon = Icons.check_circle;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // AI Result Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(resultIcon, color: resultColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Diagnosis",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        aiResult,
                        style: TextStyle(
                          color: resultColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: success ? successColor.withOpacity(0.1) : errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    success ? "Success" : "Failed",
                    style: TextStyle(
                      color: success ? successColor : errorColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // AI Details
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Confidence
                if (aiConfidence != '0')
                  _buildAiDetailRow(
                    "Confidence",
                    "${double.tryParse(aiConfidence)?.toStringAsFixed(1) ?? '0'}%",
                    primaryColor,
                  ),

                // TB Probability
                if (prediction.isNotEmpty && prediction['tb_probability'] != null)
                  _buildAiDetailRow(
                    "TB Probability",
                    "${((prediction['tb_probability'] as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(1)}%",
                    errorColor,
                  ),

                // Normal Probability
                if (prediction.isNotEmpty && prediction['normal_probability'] != null)
                  _buildAiDetailRow(
                    "Normal Probability",
                    "${((prediction['normal_probability'] as num?)?.toDouble() ?? 0 * 100).toStringAsFixed(1)}%",
                    successColor,
                  ),

                // AI Message
                if (aiMessage.isNotEmpty && aiMessage != 'No AI analysis message')
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    ),
                    child: Text(
                      aiMessage,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Doctor Notes - $patientName",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchNotes(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Loading Doctor Notes...",
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: errorColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: errorColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "Error Loading Data",
                          style: TextStyle(
                            color: errorColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      snap.error.toString(),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snap.data ?? {};
          final screening = Map<String, dynamic>.from(data["screening"] ?? {});
          final diagnosis = List<Map<String, dynamic>>.from(data["diagnosis"] ?? []);
          final recs = List<Map<String, dynamic>>.from(data["recommendations"] ?? []);
          final labs = List<Map<String, dynamic>>.from(data["labTests"] ?? []);
          final doctorName = data["doctorName"]?.toString();

          final symptoms = screening["symptoms"] is List
              ? {"Symptoms": (screening["symptoms"] as List).join(", ")}
              : (screening["symptoms"] ?? {});

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                _buildSectionTitle("AI Prediction"),
                const SizedBox(height: 12),
                _buildAiPredictionCard(screening),
                const SizedBox(height: 20),

                _buildSectionTitle("Symptoms"),
                const SizedBox(height: 12),
                _buildMapCard(Map<String, dynamic>.from(symptoms)),
                const SizedBox(height: 20),

                _buildSectionTitle("Media"),
                const SizedBox(height: 12),
                _buildMapCard(Map<String, dynamic>.from(screening["media"] ?? {})),
                const SizedBox(height: 20),

                _buildSectionTitle("Doctor's Summary"),
                const SizedBox(height: 12),
                _buildMapCard({
                  "Final Diagnosis": screening["finalDiagnosis"] ?? "Pending",
                  "Diagnosed By": screening["diagnosedBy"] ?? doctorName ?? "Not set",
                  "Status": screening["status"] ?? "N/A",
                  "Date": screening["date"]?.toString() ?? "",
                }),
                const SizedBox(height: 20),

                _buildSectionTitle("Diagnosis Records"),
                const SizedBox(height: 12),
                _buildListCards(diagnosis),
                const SizedBox(height: 20),

                _buildSectionTitle("Recommendations"),
                const SizedBox(height: 12),
                _buildListCards(recs),
                const SizedBox(height: 20),

                _buildSectionTitle("Lab Tests"),
                const SizedBox(height: 12),
                _buildListCards(labs, isLabTests: true),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}