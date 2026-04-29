import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import '../../../models/ai_case_model.dart';
import '../../../services/screening_service.dart';

class CaseDetailDialog extends StatefulWidget {
  final AiCaseModel caseData;

  const CaseDetailDialog({super.key, required this.caseData});

  @override
  State<CaseDetailDialog> createState() => _CaseDetailDialogState();
}

class _CaseDetailDialogState extends State<CaseDetailDialog> {
  String? fetchedNotes;
  String? requestedTest;
  bool isLoadingNotes = true;
  bool hasErrorFetchingNotes = false;

  AiCaseModel get caseData => widget.caseData;

  @override
  void initState() {
    super.initState();
    _fetchDiagnosisDetails();
  }

  Future<void> _fetchDiagnosisDetails() async {
    try {
      final details = await ScreeningService.fetchLatestDiagnosisStatus(
        patientId: widget.caseData.patientId,
        screeningId: widget.caseData.screeningId,
      );
      if (mounted) {
        setState(() {
          fetchedNotes = details?['notes'] as String?;
          requestedTest = details?['requestedTest'] as String?;
          isLoadingNotes = false;
          hasErrorFetchingNotes = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching diagnosis details: $e");
      if (mounted) {
        setState(() {
          isLoadingNotes = false;
          hasErrorFetchingNotes = true;
        });
      }
    }
  }

  String _getDisplayNotes() {
    List<String> notesParts = [];
    if (widget.caseData.doctorNotes?.isNotEmpty == true) {
      notesParts.add(widget.caseData.doctorNotes!);
    }
    if (fetchedNotes?.isNotEmpty == true && fetchedNotes != widget.caseData.doctorNotes) {
      notesParts.add(fetchedNotes!);
    }
    if (requestedTest?.isNotEmpty == true) {
      notesParts.add("Suggested Test: $requestedTest");
    }
    
    if (notesParts.isEmpty) {
      return 'No notes added yet';
    }
    return notesParts.join('\n\n');
  }

  void _showExpandedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 900 ? 850.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_information,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Case Details",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ID: ${caseData.screeningId}",
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 20, color: secondaryColor.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // Responsive Content
              screenWidth > 700 
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _buildLeftColumn(context)),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: _buildRightColumn()),
                  ],
                )
              : Column(
                  children: [
                    _buildLeftColumn(context),
                    const SizedBox(height: 24),
                    _buildRightColumn(),
                  ],
                ),
              
              const SizedBox(height: 32),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Close Details",
                      style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Patient Information", Icons.person_outline),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildInfoRow(context, "Patient Name", caseData.patientName),
              const Divider(height: 24),
              _buildInfoRow(context, "Upload Date", caseData.date.toLocal().toString().split(' ')[0]),
              const Divider(height: 24),
              _buildStatusRow("Diagnosis Status", caseData.status),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("Media Evidence", Icons.image_search),
        const SizedBox(height: 12),
        _buildMediaContent(),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("AI Analysis", Icons.psychology_outlined),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.05), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Analysis Result", style: TextStyle(color: secondaryColor.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  caseData.aiResult ?? 'Pending',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("Reported Symptoms", Icons.sick_outlined),
        const SizedBox(height: 12),
        if (caseData.symptoms != null && caseData.symptoms!.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: caseData.symptoms!.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "${entry.key}: ${entry.value}",
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        else
          Text("No reported symptoms", style: TextStyle(color: secondaryColor.withOpacity(0.5), fontStyle: FontStyle.italic)),
        const SizedBox(height: 24),
        _buildSectionHeader("Doctor Notes", Icons.edit_note_rounded),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: isLoadingNotes
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : hasErrorFetchingNotes
                  ? Row(
                      children: [
                        Icon(Icons.error_outline, color: errorColor, size: 16),
                        const SizedBox(width: 8),
                        const Text("Failed to load notes.", style: TextStyle(color: errorColor, fontSize: 14)),
                      ],
                    )
                  : Text(
                      _getDisplayNotes(),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _getDisplayNotes() != 'No notes added yet'
                            ? secondaryColor.withOpacity(0.8)
                            : secondaryColor.withOpacity(0.4),
                        fontStyle: _getDisplayNotes() != 'No notes added yet' ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: secondaryColor.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: secondaryColor.withOpacity(0.8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: secondaryColor.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.end,
            style: const TextStyle(color: secondaryColor, fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status) {
    Color color = accentColor;
    if (status.toLowerCase().contains('not')) color = successColor;
    else if (status.toLowerCase().contains('tb')) color = errorColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: secondaryColor.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaContent() {
    if (caseData.mediaType == 'xray') {
      return GestureDetector(
        onTap: () => _showExpandedImage(context, caseData.mediaUrl),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    caseData.mediaUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, p) => p == null ? child : Container(color: Colors.grey[100], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[100],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text("Expand", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.audiotrack), SizedBox(width: 8), Text("Audio File")]),
    );
  }
}