import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tbcare_main/features/chw/models/patient_screening_model.dart';
import 'package:tbcare_main/features/chw/services/flagged_patients_service.dart';
import 'package:tbcare_main/core/app_constants.dart';

class FlaggedPatientsScreen extends StatefulWidget {
  final Screening screening;

  const FlaggedPatientsScreen({super.key, required this.screening});

  @override
  State<FlaggedPatientsScreen> createState() => _FlaggedPatientsScreenState();
}

class _FlaggedPatientsScreenState extends State<FlaggedPatientsScreen> {
  final FlaggedPatientsService _service = FlaggedPatientsService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _chwId = FirebaseAuth.instance.currentUser!.uid;

  bool _isSending = false;
  bool _sent = false;
  Screening? _latestScreening;
  Map<String, dynamic>? _patientDetails;
  DateTime? _screeningDate;

  @override
  void initState() {
    super.initState();
    _fetchLatestScreeningData();
    _fetchPatientDetails();
  }

  Future<void> _fetchLatestScreeningData() async {
    try {
      final snap = await _db
          .collection('chws')
          .doc(_chwId)
          .collection('assigned_patients')
          .doc(widget.screening.patientId)
          .collection('screenings')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        setState(() {
          _latestScreening = Screening.fromMap(data);
          if (data['timestamp'] is Timestamp) {
            _screeningDate = (data['timestamp'] as Timestamp).toDate();
          }
        });
        print('📋 Fetched latest screening: $_latestScreening');
      } else {
        setState(() {
          _latestScreening = widget.screening;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching latest screening data: $e");
      setState(() {
        _latestScreening = widget.screening;
      });
    }
  }

  Future<void> _fetchPatientDetails() async {
    try {
      final doc = await _db
          .collection('chws')
          .doc(_chwId)
          .collection('assigned_patients')
          .doc(widget.screening.patientId)
          .get();

      if (doc.exists) {
        setState(() {
          _patientDetails = doc.data();
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching patient details: $e");
    }
  }

  String _getAiResult() {
    if (_latestScreening == null) return "Pending";

    // Try new prediction structure first
    if (_latestScreening!.prediction != null) {
      final prediction = _latestScreening!.prediction as Map<String, dynamic>;
      return prediction['class']?.toString() ?? 'Unknown';
    }

    // Try aiPrediction map
    if (_latestScreening!.aiPrediction is Map) {
      final aiPrediction = _latestScreening!.aiPrediction as Map<String, dynamic>;

      // New structure with class field
      if (aiPrediction.containsKey('class')) {
        return aiPrediction['class']?.toString() ?? 'Unknown';
      }

      // Old structure with TB/Normal
      final tb = double.tryParse(aiPrediction["TB"]?.toString() ?? "0") ?? 0;
      final normal = double.tryParse(aiPrediction["Normal"]?.toString() ?? "0") ?? 0;
      if (tb == 0 && normal == 0) return "Pending";
      return tb >= normal ? "TB" : "Normal";
    }

    return "Pending";
  }

  double _getTbProbability() {
    if (_latestScreening == null) return 0.0;

    // Method 1: Try to get from prediction.tb_probability
    if (_latestScreening!.prediction != null) {
      final prediction = _latestScreening!.prediction as Map<String, dynamic>;
      final tbProb = prediction['tb_probability'];
      if (tbProb != null) {
        return (tbProb is int) ? tbProb.toDouble() / 100.0 : (tbProb as num).toDouble() / 100.0;
      }
    }

    // Method 2: Try from aiPrediction
    if (_latestScreening!.aiPrediction is Map) {
      final aiPrediction = _latestScreening!.aiPrediction as Map<String, dynamic>;
      if (aiPrediction.containsKey('tb_probability')) {
        final tbProb = aiPrediction['tb_probability'];
        return (tbProb is int) ? tbProb.toDouble() / 100.0 : (tbProb as num).toDouble() / 100.0;
      }
    }

    // Method 3: Fallback to aiConfidence if TB
    final aiResult = _getAiResult();
    if (aiResult.toLowerCase() == 'tb' || aiResult.toLowerCase() == 'tuberculosis') {
      return _getAiConfidence() / 100.0;
    }

    return 0.0;
  }

  double _getNormalProbability() {
    if (_latestScreening == null) return 0.0;

    // Method 1: Try to get from prediction.normal_probability
    if (_latestScreening!.prediction != null) {
      final prediction = _latestScreening!.prediction as Map<String, dynamic>;
      final normalProb = prediction['normal_probability'];
      if (normalProb != null) {
        return (normalProb is int) ? normalProb.toDouble() / 100.0 : (normalProb as num).toDouble() / 100.0;
      }
    }

    // Method 2: Try from aiPrediction
    if (_latestScreening!.aiPrediction is Map) {
      final aiPrediction = _latestScreening!.aiPrediction as Map<String, dynamic>;
      if (aiPrediction.containsKey('normal_probability')) {
        final normalProb = aiPrediction['normal_probability'];
        return (normalProb is int) ? normalProb.toDouble() / 100.0 : (normalProb as num).toDouble() / 100.0;
      }
    }

    // Method 3: Calculate from TB probability
    final tbProb = _getTbProbability();
    return 1.0 - tbProb;
  }

  double _getAiConfidence() {
    if (_latestScreening == null) return 0.0;

    // Get from prediction.confidence
    if (_latestScreening!.prediction != null) {
      final prediction = _latestScreening!.prediction as Map<String, dynamic>;
      final confidence = prediction['confidence'];
      if (confidence != null) {
        return (confidence is int) ? confidence.toDouble() : (confidence as num).toDouble();
      }
    }

    // Fallback to aiConfidence field
    return _latestScreening!.aiConfidencePercent;
  }

  Color _getRiskColor(String result) {
    switch (result.toLowerCase()) {
      case 'tb':
      case 'tuberculosis':
        return errorColor;
      case 'normal':
        return successColor;
      default:
        return warningColor;
    }
  }

  IconData _getRiskIcon(String result) {
    switch (result.toLowerCase()) {
      case 'tb':
      case 'tuberculosis':
        return Icons.warning;
      case 'normal':
        return Icons.check_circle;
      default:
        return Icons.schedule;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "No date";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final screeningDay = DateTime(date.year, date.month, date.day);

    if (screeningDay == today) {
      return "Today";
    } else if (screeningDay == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  Future<void> _handleSendToDoctor() async {
    if (_isSending || _sent) return;

    final screeningToSend = _latestScreening ?? widget.screening;

    setState(() => _isSending = true);
    try {
      await _service.sendToDoctor(screeningToSend);

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Patient referred to doctor successfully"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to refer patient: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Enhanced Patient Info Card (matching mobile)
  Widget _buildPatientInfoCard() {
    final screening = _latestScreening ?? widget.screening;
    final assignedDoctor = screening.assignedDoctorName ?? _patientDetails?['assignedDoctorName'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.9), primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  screening.patientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: ${screening.patientId.substring(0, 8)}...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                if (assignedDoctor != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Assigned to: Dr. $assignedDoctor",
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
                if (_screeningDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.7), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(_screeningDate),
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced AI Details Card with probability bars (matching mobile)
  Widget _buildAiDetailsCard() {
    final aiResult = _getAiResult();
    final riskColor = _getRiskColor(aiResult);
    final riskIcon = _getRiskIcon(aiResult);
    final tbProbability = _getTbProbability();
    final normalProbability = _getNormalProbability();
    final aiConfidence = _getAiConfidence();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Result Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(riskIcon, color: riskColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Analysis Result",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        aiResult.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: riskColor),
                  ),
                  child: Text(
                    "${(aiConfidence).toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Probability Bars (matching mobile)
            Column(
              children: [
                // TB Probability
                _buildProbabilityRow(
                  "TB Probability",
                  tbProbability * 100,
                  errorColor,
                ),
                const SizedBox(height: 16),
                // Normal Probability
                _buildProbabilityRow(
                  "Normal Probability",
                  normalProbability * 100,
                  successColor,
                ),
                const SizedBox(height: 16),
                // AI Confidence
                _buildProbabilityRow(
                  "AI Confidence",
                  aiConfidence,
                  primaryColor,
                ),
              ],
            ),

            // Additional AI Info
            if (_latestScreening?.message != null &&
                _latestScreening!.message != 'No AI analysis message' &&
                _latestScreening!.message!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _latestScreening!.message!,
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
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilityRow(String label, double percentage, Color color) {
    final safePercentage = percentage.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              "${safePercentage.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: safePercentage / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // Enhanced Symptoms Card
  Widget _buildSymptomsCard() {
    final symptoms = _latestScreening?.symptoms ?? widget.screening.symptoms;
    final isList = symptoms is List<String>;
    final symptomList = isList ? symptoms as List<String> : <String>[];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: accentColor),
                const SizedBox(width: 8),
                const Text(
                  "Symptoms Detected",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text("${symptomList.length} symptoms"),
                  backgroundColor: accentColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (symptomList.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: symptomList.map((symptom) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          symptom,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      "No symptoms recorded",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Enhanced Status Card
  Widget _buildStatusCard() {
    final currentStatus = _latestScreening?.status ?? widget.screening.status;
    final aiResult = _getAiResult();

    Color statusColor;
    String statusText;
    IconData statusIcon;
    String statusDescription;

    switch (currentStatus?.toLowerCase() ?? 'pending') {
      case 'ai_completed':
      case 'dl_completed':
        statusColor = Colors.blue;
        statusText = 'AI Analysis Complete';
        statusIcon = Icons.check_circle;
        statusDescription = aiResult.toLowerCase() == 'tb'
            ? 'TB detected. Ready for doctor referral'
            : 'Normal result. Ready for review';
        break;
      case 'sent_to_doctor':
        statusColor = Colors.green;
        statusText = 'Referred to Doctor';
        statusIcon = Icons.send;
        statusDescription = 'Patient has been sent to doctor for review';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'Pending Analysis';
        statusIcon = Icons.schedule;
        statusDescription = 'Awaiting AI analysis results';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Screening Status",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusDescription,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Referral Actions
  Widget _buildReferralActions() {
    final currentStatus = _latestScreening?.status ?? widget.screening.status;
    final aiResult = _getAiResult();
    final isFlagged = aiResult.toLowerCase() == 'tb' || aiResult.toLowerCase() == 'tuberculosis';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Referral Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            if (currentStatus == 'ai_completed' || currentStatus == 'dl_completed')
              Column(
                children: [
                  if (isFlagged)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: errorColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: errorColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "TB detected - Immediate referral recommended",
                              style: TextStyle(color: errorColor, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _handleSendToDoctor,
                      icon: _isSending
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.send_to_mobile),
                      label: Text(
                        _sent ? "✅ Referred" : (_isSending ? "Processing..." :
                        isFlagged ? "Urgent Referral to Doctor" : "Send to Doctor for Review"),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFlagged ? errorColor : successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ),
                ],
              )
            else if (currentStatus == 'sent_to_doctor')
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Already Referred ✓",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Patient has been sent to doctor for review",
                            style: TextStyle(color: Colors.green[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.orange[600], size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Awaiting Analysis",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Waiting for AI results before referral",
                            style: TextStyle(color: Colors.orange[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Enhanced Timeline Card (matching mobile)
  Widget _buildTimelineCard() {
    final currentStatus = _latestScreening?.status ?? widget.screening.status;

    final steps = [
      {"title": "Screening Completed", "completed": true, "icon": Icons.check_circle},
      {"title": "AI Analysis", "completed": currentStatus == 'ai_completed' || currentStatus == 'dl_completed' || currentStatus == 'sent_to_doctor', "icon": Icons.psychology},
      {"title": "Doctor Referral", "completed": currentStatus == 'sent_to_doctor', "icon": Icons.medical_services},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Process Timeline",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            ...steps.asMap().entries.map((entry) {
              final step = entry.value;
              final isCompleted = step['completed'] as bool;
              final isLast = entry.key == steps.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        size: 20,
                        color: isCompleted ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCompleted ? "✓ Completed" : "Pending",
                            style: TextStyle(
                              fontSize: 12,
                              color: isCompleted ? Colors.green : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      const Icon(Icons.check, color: Colors.green, size: 20),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWebDashboard() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getRiskColor(_getAiResult()).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.flag, color: _getRiskColor(_getAiResult())),
            ),
            const SizedBox(width: 12),
            Text(
              _latestScreening?.patientName ?? widget.screening.patientName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
          ],
        ),
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 3,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Patient Info and AI Analysis
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientInfoCard(),
                    const SizedBox(height: 24),
                    _buildAiDetailsCard(),
                    const SizedBox(height: 24),
                    _buildSymptomsCard(),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right Column - Actions and Timeline
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    _buildReferralActions(),
                    const SizedBox(height: 24),
                    _buildTimelineCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebDashboard();
    } else {
      // Mobile layout
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            _latestScreening?.patientName ?? widget.screening.patientName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildPatientInfoCard(),
              const SizedBox(height: 24),
              _buildAiDetailsCard(),
              const SizedBox(height: 20),
              _buildSymptomsCard(),
              const SizedBox(height: 32),
              _buildReferralActions(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }
  }
}