import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchLatestScreeningData();
  }

  /// 🔄 Fetch latest screening with NEW AI structure
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
        print('📋 Fetched latest screening: $data');

        setState(() {
          _latestScreening = Screening.fromMap(data);
        });
      } else {
        // If no screening found in assigned_patients, use the passed screening
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

  String _getAiResult() {
    if (_latestScreening == null) return "Pending";

    if (_latestScreening!.prediction != null) {
      return _latestScreening!.prediction!['class']?.toString() ?? 'Unknown';
    }

    if (_latestScreening!.aiPrediction is Map) {
      final aiPrediction = _latestScreening!.aiPrediction as Map<String, dynamic>;
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
      final tbProb = _latestScreening!.prediction!['tb_probability'];
      if (tbProb != null) {
        return (tbProb is int) ? tbProb.toDouble() / 100.0 : (tbProb as num).toDouble() / 100.0;
      }
    }

    // Method 2: Fallback to aiConfidence if TB
    final aiResult = _getAiResult();
    if (aiResult.toLowerCase() == 'tuberculosis' || aiResult.toLowerCase() == 'tb') {
      return _getAiConfidence() / 100.0;
    }

    return 0.0;
  }

  double _getNormalProbability() {
    if (_latestScreening == null) return 0.0;

    // Method 1: Try to get from prediction.normal_probability
    if (_latestScreening!.prediction != null) {
      final normalProb = _latestScreening!.prediction!['normal_probability'];
      if (normalProb != null) {
        return (normalProb is int) ? normalProb.toDouble() / 100.0 : (normalProb as num).toDouble() / 100.0;
      }
    }

    // Method 2: Calculate from TB probability
    final tbProb = _getTbProbability();
    return 1.0 - tbProb;
  }

  double _getAiConfidence() {
    if (_latestScreening == null) return 0.0;

    // Get from prediction.confidence
    if (_latestScreening!.prediction != null) {
      final confidence = _latestScreening!.prediction!['confidence'];
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
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context);
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

  Widget _buildAiDetailsCard() {
    final aiResult = _getAiResult();
    final riskColor = _getRiskColor(aiResult);
    final riskIcon = _getRiskIcon(aiResult);
    final tbProbability = _getTbProbability();
    final normalProbability = _getNormalProbability();
    final aiConfidence = _getAiConfidence();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        aiResult.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Probability Bars
            Column(
              children: [
                // TB Probability
                _buildProbabilityRow(
                  "TB Probability",
                  tbProbability * 100,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                // Normal Probability
                _buildProbabilityRow(
                  "Normal Probability",
                  normalProbability * 100,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                // AI Confidence
                _buildProbabilityRow(
                  "AI Confidence",
                  aiConfidence,
                  primaryColor,
                ),
              ],
            ),

            // Additional AI Info
            if (_latestScreening?.message != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _latestScreening!.message!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilityRow(String label, double percentage, Color color) {
    // Ensure percentage is between 0 and 100
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
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: safePercentage / 100,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildSymptomsCard() {
    final symptoms = _latestScreening?.symptoms ?? widget.screening.symptoms;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
              ],
            ),
            const SizedBox(height: 16),
            if (symptoms.isNotEmpty)
              ...symptoms.map((symptom) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        symptom,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
            else
              Text(
                "No symptoms recorded",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    final screening = widget.screening;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withOpacity(0.9), primaryColor],
          ),
          borderRadius: BorderRadius.circular(20),
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
                  if (screening.assignedDoctorName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Assigned to: Dr. ${screening.assignedDoctorName}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferButton() {
    final aiResult = _getAiResult().toLowerCase();
    final isFlagged = aiResult == 'tb' || aiResult == 'tuberculosis';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_isSending || _sent) ? null : _handleSendToDoctor,
        icon: _isSending
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.send),
        label: Text(
          _sent ? "Sent" : (_isSending ? "Sending..." :
          isFlagged ? "Refer to Doctor" : "Send for Review"),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFlagged ? errorColor : successColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _latestScreening?.status ?? widget.screening.status;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Patient Referral - ${widget.screening.patientName}",
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
            /// 🧍 Patient Info
            _buildPatientInfoCard(),

            const SizedBox(height: 24),

            /// 🤖 AI Analysis Details
            _buildAiDetailsCard(),

            const SizedBox(height: 20),

            /// 😷 Symptoms
            _buildSymptomsCard(),

            const SizedBox(height: 32),

            /// 📤 Action Buttons
            if (currentStatus == 'ai_completed')
              _buildReferButton()
            else if (currentStatus == 'sent_to_doctor')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      "✅ Already referred to doctor",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, color: Colors.orange, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      "⏳ Awaiting AI result or referral",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}