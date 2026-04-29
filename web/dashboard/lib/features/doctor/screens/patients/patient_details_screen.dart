import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/patient_model.dart';
import 'package:tbcare_main/features/doctor/models/screening_model.dart';
import 'package:tbcare_main/features/doctor/services/screening_service.dart';
import '../assessments/diagnose_screen.dart';
import 'package:tbcare_main/core/utils/string_extensions.dart';

class PatientDetailScreen extends StatefulWidget {
  final PatientModel patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  List<ScreeningModel> screenings = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScreenings();
  }

  Future<void> _loadScreenings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await ScreeningService.fetchScreeningsForPatient(
        widget.patient.uid,
      );
      if (!mounted) return;
      setState(() {
        screenings = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading screenings: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load screenings. Please try again.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Error loading screenings.'), backgroundColor: errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive horizontal padding for web dashboard
    final double horizontalMargin = screenWidth > 900 ? screenWidth * 0.15 : 0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "Patient Profile",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, size: 20, color: Colors.white),
            ),
            onPressed: _loadScreenings,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : errorMessage != null
              ? _buildErrorState()
              : Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: screenWidth > 900 ? 1200 : double.infinity),
                    margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Patient Identity Header
                        SliverToBoxAdapter(child: _buildPatientHeader()),

                        // Screening History Section
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 24, bottom: 16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Screening History",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: secondaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "${screenings.length} Records",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: secondaryColor.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        screenings.isEmpty
                            ? SliverFillRemaining(child: _buildEmptyState())
                            : SliverPadding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildScreeningCard(screenings[index]),
                                    childCount: screenings.length,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
                  image: widget.patient.photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.patient.photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.patient.photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 40, color: primaryColor)
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildBadge(
                          icon: Icons.cake_outlined,
                          text: "${widget.patient.age} Yrs",
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          icon: widget.patient.gender.toLowerCase() == 'male' 
                              ? Icons.male 
                              : Icons.female,
                          text: widget.patient.gender,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text(
                  "Health Status:",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.patient.diagnosisStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.patient.diagnosisStatus.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
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

  Color _getStatusColor(String status) {
    if (status == 'TB') return errorColor;
    if (status == 'Not TB') return successColor;
    return accentColor;
  }

  Widget _buildBadge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildScreeningCard(ScreeningModel screening) {
    final bool isFinal = screening.finalDiagnosis != null && screening.finalDiagnosis!.isNotEmpty;
    final String statusText = isFinal ? screening.finalDiagnosis! : "Pending Review";
    final Color statusColor = _getStatusColor(statusText);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.1),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Icon(Icons.event_note, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          screening.date.toLocal().toString().split(' ')[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          "Assessment Date",
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Symptoms Chip Group
                  if (screening.symptoms.entries.where((e) => e.value == true).isNotEmpty) ...[
                    _buildSectionTitle("PATIENT SYMPTOMS"),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: screening.symptoms.entries
                          .where((e) => e.value == true)
                          .map((e) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: primaryColor.withOpacity(0.1)),
                                ),
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: secondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // AI Analysis Section
                  _buildSectionTitle("AI CLINICAL ANALYSIS"),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.03)),
                    ),
                    child: Column(
                      children: screening.aiPrediction.entries.map((e) {
                        final isConfidence = e.key.toLowerCase() == 'confidence';
                        final val = isConfidence 
                            ? "${((e.value as num) * 100).toStringAsFixed(1)}%"
                            : e.value.toString();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key.capitalize(),
                                style: TextStyle(
                                  color: secondaryColor.withOpacity(0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                val,
                                style: TextStyle(
                                  color: isConfidence ? primaryColor : secondaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: secondaryColor.withOpacity(0.4),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: errorColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(color: secondaryColor, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadScreenings,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Try Again", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: secondaryColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "No screening records found",
            style: TextStyle(
              color: secondaryColor.withOpacity(0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}