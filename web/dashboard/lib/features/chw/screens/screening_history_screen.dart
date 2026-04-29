import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/models/screening_patient_list_model.dart';
import 'package:tbcare_main/features/chw/services/screening_patient_list_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

class ScreeningHistoryDashboard extends StatelessWidget {
  final Patient patient;
  final PatientService _service = PatientService();

  ScreeningHistoryDashboard({super.key, required this.patient});

  // Define colors locally
  Color get primaryColor => Color(0xFF2196F3); // Blue
  Color get secondaryColor => Color(0xFF666666); // Dark Grey
  Color get bgColor => Color(0xFFF5F7FA); // Light Grey

  @override
  Widget build(BuildContext context) {
    // Choose layout based on platform
    if (kIsWeb) {
      return _buildWebLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${patient.name}'s Screening History",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Patient ID: ${patient.id}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back),
                        label: Text("Back to Patients"),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: StreamBuilder<List<Screening>>(
                      stream: _service.getScreenings(patient.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildErrorState();
                        }
                        if (!snapshot.hasData) {
                          return _buildLoadingState();
                        }

                        final screenings = snapshot.data!;
                        if (screenings.isEmpty) {
                          return _buildEmptyState();
                        }

                        return _buildScreeningList(screenings);
                      },
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

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.medical_services, color: Colors.white, size: 30),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "CHW Portal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  "Screening History",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Navigation Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildNavItem(Icons.dashboard, "Dashboard"),
                _buildNavItem(Icons.group, "Patients"),
                _buildNavItem(Icons.assignment, "Screenings", true),
                _buildNavItem(Icons.timeline, "Follow-ups"),
                _buildNavItem(Icons.report, "Reports"),
              ],
            ),
          ),

          // Footer/User Info
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CHW Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Community Health Worker",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, [bool isActive = false]) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
      ),
    );
  }

  Widget _buildScreeningList(List<Screening> screenings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Symptoms",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "AI Prediction",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Cough Audio",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Date",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Screening Items
          Expanded(
            child: ListView.builder(
              itemCount: screenings.length,
              itemBuilder: (context, index) {
                final screening = screenings[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    color: index % 2 == 0 ? Colors.white : bgColor,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Symptoms
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: screening.symptoms.isEmpty
                                    ? [
                                  Chip(
                                    label: Text('No symptoms'),
                                    backgroundColor: primaryColor,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                ]
                                    : screening.symptoms.map((symptom) => Chip(
                                  label: Text(symptom),
                                  backgroundColor: primaryColor,
                                  labelStyle: TextStyle(color: Colors.white),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),

                        // AI Prediction
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              _formatAiPrediction(screening.aiPrediction),
                              style: TextStyle(
                                color: secondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        // Cough Audio
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Row(
                              children: [
                                Icon(
                                  screening.coughAudioPath.isEmpty
                                      ? Icons.mic_off
                                      : Icons.mic,
                                  color: screening.coughAudioPath.isEmpty
                                      ? Colors.grey
                                      : Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  screening.coughAudioPath.isEmpty ? 'No audio' : 'Available',
                                  style: TextStyle(
                                    color: screening.coughAudioPath.isEmpty
                                        ? Colors.grey
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Date
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              screening.timestamp != null
                                  ? DateFormat('dd MMM yyyy').format(screening.timestamp!)
                                  : 'Unknown',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatAiPrediction(dynamic aiPrediction) {
    if (aiPrediction is String) {
      return aiPrediction;
    } else if (aiPrediction is Map) {
      return aiPrediction.toString();
    }
    return "Pending";
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            SizedBox(height: 20),
            Text(
              "Error loading screenings",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 20),
          Text(
            "Loading screening history...",
            style: TextStyle(
              color: secondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment,
              color: Colors.grey.shade300,
              size: 60,
            ),
            SizedBox(height: 20),
            Text(
              "No screenings yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "${patient.name} has no screening records",
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    // Mobile layout - same as original app
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: Text(
          "${patient.name}'s History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Screening>>(
        stream: _service.getScreenings(patient.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading screenings",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final screenings = snapshot.data!;
          if (screenings.isEmpty) {
            return Center(
              child: Text(
                "No screenings yet",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: screenings.length,
            itemBuilder: (context, i) {
              final s = screenings[i];
              return Card(
                color: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: s.symptoms.isEmpty
                        ? [
                      Chip(
                        label: Text('No symptoms'),
                        backgroundColor: primaryColor,
                        labelStyle: TextStyle(color: Colors.white),
                      )
                    ]
                        : s.symptoms.map((sym) => Chip(
                      label: Text(sym),
                      backgroundColor: primaryColor,
                      labelStyle: TextStyle(color: Colors.white),
                    )).toList(),
                  ),
                  subtitle: Text(
                    "Date: ${s.timestamp ?? 'Unknown'}\nAI: ${s.aiPrediction}\nCough: ${s.coughAudioPath.isEmpty ? 'no audio' : 'available'}",
                    style: TextStyle(color: Colors.white70),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}