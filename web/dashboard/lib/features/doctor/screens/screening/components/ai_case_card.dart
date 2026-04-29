import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import '../../../models/ai_case_model.dart';
import '../../../services/screening_service.dart';
import 'case_detail_dialog.dart';
import 'case_action_modal.dart';
import '../../assessments/test_review_screen.dart';

class _DiagStatus {
  static const tb = 'TB';
  static const notTb = 'Not TB';
  static const lab = 'Needs Lab Test';
}

class AiCaseCard extends StatefulWidget {
  final AiCaseModel caseData;

  const AiCaseCard({super.key, required this.caseData});

  @override
  State<AiCaseCard> createState() => _AiCaseCardState();
}

class _AiCaseCardState extends State<AiCaseCard> {
  late AiCaseModel _currentCaseData;
  late String caseStatus;
  String? doctorNote;
  String? testRequested;
  bool showReviewButton = false;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _currentCaseData = widget.caseData;
    caseStatus = _currentCaseData.status;
    doctorNote = _currentCaseData.doctorNotes;
    _fetchLatestDiagnosisStatus();
  }

  Future<void> _fetchLatestDiagnosisStatus() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final diagnosisData = await ScreeningService.fetchLatestDiagnosisStatus(
        patientId: widget.caseData.patientId,
        screeningId: widget.caseData.screeningId,
      );

      if (diagnosisData != null) {
        final status = diagnosisData['status'] as String;
        final notes = diagnosisData['notes'] as String?;
        final requestedTest = diagnosisData['requestedTest'] as String?;

        if (!mounted) return;
        setState(() {
          caseStatus = status.isNotEmpty ? status : caseStatus;
          doctorNote = notes ?? doctorNote;
          testRequested = requestedTest?.isNotEmpty == true
              ? requestedTest
              : testRequested;
          showReviewButton = status == _DiagStatus.lab;
          
          _currentCaseData = _currentCaseData.copyWith(
            status: caseStatus,
            doctorNotes: doctorNote,
          );
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking diagnosis status: $e");
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load diagnosis status';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildMedia(),
            const SizedBox(height: 12),
            _buildDetails(),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              _buildErrorBanner(),
            ],
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentCaseData.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: bodySize,
                        color: secondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _currentCaseData.date.toLocal().toString().split(' ')[0],
                      style: TextStyle(
                        color: secondaryColor.withOpacity(0.6),
                        fontSize: captionSize,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(caseStatus),
      ],
    );
  }

  Widget _buildMedia() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: secondaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.audiotrack,
                  color: accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Cough audio analysis",
                  style: TextStyle(
                    color: secondaryColor.withOpacity(0.8),
                    fontSize: captionSize,
                  ),
                ),
              ),
              _buildMediaTypeBadge('Audio', accentColor),
            ],
          ),
          
          if (_currentCaseData.mediaType == "xray" || _currentCaseData.mediaType == "both") ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "X-ray image analysis",
                    style: TextStyle(
                      color: secondaryColor.withOpacity(0.8),
                      fontSize: captionSize,
                    ),
                  ),
                ),
                _buildMediaTypeBadge('X-ray', primaryColor),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _currentCaseData.mediaUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: accentColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "AI Analysis Results:",
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: captionSize,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${_currentCaseData.aiResult ?? 'Analysis pending'} ${_currentCaseData.aiConfidence != null ? '(${_currentCaseData.aiConfidence}%)' : ''}",
            style: TextStyle(
              color: secondaryColor.withOpacity(0.8),
              fontSize: captionSize,
            ),
          ),
          if (testRequested != null && testRequested!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.science,
                  color: warningColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  "Requested Test: ",
                  style: TextStyle(
                    color: warningColor,
                    fontWeight: FontWeight.w600,
                    fontSize: captionSize,
                  ),
                ),
                Expanded(
                  child: Text(
                    testRequested!,
                    style: TextStyle(
                      color: secondaryColor.withOpacity(0.8),
                      fontSize: captionSize,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: errorColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: errorColor,
                fontSize: captionSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => CaseDetailDialog(caseData: _currentCaseData),
            ),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text("View Details"),
            style: OutlinedButton.styleFrom(
              foregroundColor: secondaryColor,
              side: BorderSide(color: secondaryColor.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => CaseActionModal(
                caseData: _currentCaseData,
                onActionSaved: (diagnosis, notes, requestedTest) {
                  setState(() {
                    caseStatus = diagnosis;
                    doctorNote = notes;
                    testRequested = requestedTest;
                    showReviewButton = (diagnosis == _DiagStatus.lab);
                    
                    _currentCaseData = _currentCaseData.copyWith(
                      status: diagnosis,
                      doctorNotes: notes,
                    );
                  });
                },
              ),
            ),
            icon: const Icon(Icons.medical_services, size: 16),
            label: const Text("Diagnose"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        if (showReviewButton) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestReviewScreen(caseData: _currentCaseData),
                  ),
                );
                _fetchLatestDiagnosisStatus();
              },
              icon: const Icon(Icons.science_outlined, size: 16),
              label: const Text("Review Tests"),
              style: ElevatedButton.styleFrom(
                backgroundColor: warningColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'tb':
        statusColor = errorColor;
        break;
      case 'not tb':
        statusColor = successColor;
        break;
      case 'needs lab test':
        statusColor = warningColor;
        break;
      default:
        statusColor = accentColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: captionSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMediaTypeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}