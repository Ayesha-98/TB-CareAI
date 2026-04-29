import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbcare_main/features/chw/models/followup_patient_model.dart';
import 'package:tbcare_main/features/chw/services/followup_patient_service.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/chw/screens/doctor_notes_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  final _service = FollowUpService();
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final Map<String, bool> _doneStatus = {}; // track done button per patient
  final Map<String, bool> _expandedStatus = {}; // track expanded cards
  String _filterStatus = 'all'; // 'all', 'pending', 'completed'

  @override
  Widget build(BuildContext context) {
    // Choose layout based on platform
    if (kIsWeb) {
      return _buildWebLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),

          // Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
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
                            "Patient Follow-ups",
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Track and manage patient follow-up appointments",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: primaryColor, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd MMM yyyy').format(DateTime.now()),
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter and Stats Bar
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Filter Buttons
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            _buildFilterButton('All', 'all'),
                            _buildFilterButton('Pending', 'pending'),
                            _buildFilterButton('Completed', 'completed'),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Stats Cards
                      Row(
                        children: [
                          _buildStatCard("Total", "24", Icons.group),
                          const SizedBox(width: 12),
                          _buildStatCard("Pending", "12", Icons.pending, warningColor),
                          const SizedBox(width: 12),
                          _buildStatCard("Completed", "12", Icons.check_circle, successColor),
                        ],
                      ),
                    ],
                  ),
                ),

                // Patients Table
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: StreamBuilder<List<Screening>>(
                      stream: _service.getDoctorFollowUps(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return _buildErrorCard(snap.error.toString());
                        }

                        if (snap.connectionState == ConnectionState.waiting) {
                          return _buildLoadingCard();
                        }

                        final list = snap.data ?? [];
                        if (list.isEmpty) {
                          return _buildEmptyState();
                        }

                        // Filter based on selection
                        final filteredList = _filterPatients(list);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Patient",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        "AI Prediction",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        "Status",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        "Date",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        "Actions",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Table Rows
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, i) {
                                    final s = filteredList[i];
                                    _doneStatus.putIfAbsent(s.id, () => false);
                                    _expandedStatus.putIfAbsent(s.id, () => false);

                                    String date = "Unknown";
                                    if (s.timestamp != null) {
                                      try {
                                        date = _dateFormat.format(s.timestamp!);
                                      } catch (_) {
                                        date = s.timestamp.toString();
                                      }
                                    }

                                    final isPending = s.followUpStatus?.toLowerCase() != 'completed';

                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                        color: i.isEven ? bgColor : Colors.white,
                                      ),
                                      child: Column(
                                        children: [
                                          // Main Row
                                          Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Row(
                                              children: [
                                                // Patient Info
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: primaryColor.withOpacity(0.1),
                                                          shape: BoxShape.circle,
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
                                                              s.patientName,
                                                              style: TextStyle(
                                                                color: secondaryColor,
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              "ID: ${s.patientId.substring(0, 8)}...",
                                                              style: TextStyle(
                                                                color: Colors.grey.shade600,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(width: 16),

                                                // AI Prediction
                                                Expanded(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: primaryColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      s.aiPrediction,
                                                      style: TextStyle(
                                                        color: primaryColor,
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 16),

                                                // Status
                                                Expanded(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: isPending
                                                          ? warningColor.withOpacity(0.1)
                                                          : successColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      s.followUpStatus ?? 'Pending',
                                                      style: TextStyle(
                                                        color: isPending ? warningColor : successColor,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 16),

                                                // Date
                                                Expanded(
                                                  child: Text(
                                                    date,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 2,
                                                  ),
                                                ),

                                                const SizedBox(width: 16),

                                                // Actions
                                                SizedBox(
                                                  width: 200,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton.icon(
                                                          icon: const Icon(Icons.visibility, size: 16),
                                                          label: const Text("View"),
                                                          style: OutlinedButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                            side: BorderSide(color: primaryColor),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => DoctorNotesScreen(
                                                                  patientId: s.patientId,
                                                                  screeningId: s.id,
                                                                  patientName: s.patientName,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: ElevatedButton.icon(
                                                          icon: const Icon(Icons.check, size: 16),
                                                          label: const Text("Done"),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: isPending ? primaryColor : successColor,
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                          ),
                                                          onPressed: _doneStatus[s.id]! || !isPending
                                                              ? null
                                                              : () async {
                                                            setState(() => _doneStatus[s.id] = true);
                                                            await _service.markCompleted(
                                                                s.id, s.patientId, s.patientName);
                                                            if (mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('${s.patientName} marked completed'),
                                                                  backgroundColor: successColor,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Expanded Details
                                          if (_expandedStatus[s.id] == true)
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: bgColor,
                                                border: Border(
                                                  top: BorderSide(color: Colors.grey.shade200),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  // Additional Details
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "Additional Information",
                                                          style: TextStyle(
                                                            color: secondaryColor,
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          "Follow-up notes and details will appear here...",
                                                          style: TextStyle(
                                                            color: Colors.grey.shade600,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.expand_less,
                                                      color: primaryColor,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _expandedStatus[s.id] = false;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
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
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medical_services, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "CHW Portal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Follow-up Management",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildNavItem(Icons.dashboard, "Dashboard"),
                _buildNavItem(Icons.group, "Patients"),
                _buildNavItem(Icons.assignment, "Screenings"),
                _buildNavItem(Icons.timeline, "Follow-ups", true),
                _buildNavItem(Icons.report, "Reports"),
              ],
            ),
          ),

          // Statistics
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Follow-ups",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "12 Pending",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "8:00 AM - 5:00 PM",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // User Profile
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
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
                          color: Colors.white,
                          fontSize: 12,
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
    );
  }

  Widget _buildNavItem(IconData icon, String title, [bool isActive = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isActive = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (color ?? primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color ?? primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Screening> _filterPatients(List<Screening> patients) {
    if (_filterStatus == 'all') return patients;
    if (_filterStatus == 'pending') {
      return patients.where((p) => p.followUpStatus?.toLowerCase() != 'completed').toList();
    }
    if (_filterStatus == 'completed') {
      return patients.where((p) => p.followUpStatus?.toLowerCase() == 'completed').toList();
    }
    return patients;
  }

  Widget _buildErrorCard(String error) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: errorColor, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              "Error Loading Data",
              style: TextStyle(
                color: errorColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Loading Follow-ups...",
            style: TextStyle(
              color: secondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Fetching patient follow-up data",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.group, color: Colors.grey.shade300, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              "No Follow-ups Found",
              style: TextStyle(
                color: secondaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "No patients have been sent for follow-up appointments yet",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Original Mobile Layout (unchanged)
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Follow-ups', style: TextStyle(color: Colors.white)),
        backgroundColor: secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Screening>>(
        stream: _service.getDoctorFollowUps(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'No patients sent to doctor yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];

              // Track button disabled state
              _doneStatus.putIfAbsent(s.id, () => false);

              String date = "Unknown";
              if (s.timestamp != null) {
                try {
                  date = _dateFormat.format(s.timestamp!);
                } catch (_) {
                  date = s.timestamp.toString();
                }
              }

              return Card(
                color: secondaryColor,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.person, color: primaryColor),
                  title: Text(s.patientName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Date: $date\nAI: ${s.aiPrediction}\nStatus: ${s.followUpStatus}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorNotesScreen(
                                patientId: s.patientId,
                                screeningId: s.id,
                                patientName: s.patientName,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        onPressed: _doneStatus[s.id]!
                            ? null
                            : () async {
                          setState(() => _doneStatus[s.id] = true);
                          await _service.markCompleted(
                              s.id, s.patientId, s.patientName);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${s.patientName} marked completed')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}