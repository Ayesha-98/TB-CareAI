import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/models/screening_patient_list_model.dart';
import 'package:tbcare_main/features/chw/services/screening_patient_list_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screening_history_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListDashboardState();
}

class _PatientListDashboardState extends State<PatientListScreen> {
  final PatientService _service = PatientService();
  bool _loading = true;
  List<Patient> _patients = [];

  // Define colors locally
  Color get primaryColor => Color(0xFF2196F3); // Blue
  Color get secondaryColor => Color(0xFF666666); // Dark Grey
  Color get bgColor => Color(0xFFF5F7FA); // Light Grey

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    try {
      _patients = await _service.getScreenedPatients();
    } catch (e) {
      debugPrint('Failed to load patients: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openHistory(Patient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreeningHistoryDashboard(patient: patient),
      ),
    );
  }

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
                            "Patient Management",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Manage screened patients and view their history",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _loadPatients,
                        icon: Icon(Icons.refresh),
                        label: Text("Refresh"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: _buildPatientList(),
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
                  "Patient Management",
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
                _buildNavItem(Icons.group, "Patients", true),
                _buildNavItem(Icons.assignment, "Screenings"),
                _buildNavItem(Icons.timeline, "Follow-ups"),
                _buildNavItem(Icons.report, "Reports"),
              ],
            ),
          ),

          // Stats/Summary
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Patient Summary",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "${_patients.length} Patients",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Last updated: Today",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
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

  Widget _buildPatientList() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 20),
            Text(
              "Loading patients...",
              style: TextStyle(
                color: secondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_patients.isEmpty) {
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
                Icons.group,
                color: Colors.grey.shade300,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                "No Patients Found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "No screened patients available",
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPatients,
                icon: Icon(Icons.refresh),
                label: Text("Refresh"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                  child: Text(
                    "Patient Name",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Patient ID",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    "Actions",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: ListView.builder(
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    color: index % 2 == 0 ? Colors.white : bgColor,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Patient Name
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
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Patient ID
                        Expanded(
                          child: Text(
                            patient.id.length > 20
                                ? '${patient.id.substring(0, 20)}...'
                                : patient.id,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontFamily: 'Monospace',
                            ),
                          ),
                        ),

                        // Actions
                        SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _openHistory(patient),
                                icon: Icon(Icons.history, size: 16),
                                label: Text("History"),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  side: BorderSide(color: primaryColor),
                                ),
                              ),
                            ],
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

  Widget _buildMobileLayout(BuildContext context) {
    // Mobile layout - same as original app
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "My Patients",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _patients.isEmpty
          ? Center(
        child: Text(
          "No screened patients found",
          style: TextStyle(color: Colors.white),
        ),
      )
          : ListView.separated(
        padding: EdgeInsets.all(12),
        separatorBuilder: (_, __) => SizedBox(height: 8),
        itemCount: _patients.length,
        itemBuilder: (context, i) {
          final p = _patients[i];
          return Card(
            color: secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                p.name,
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "ID: ${p.id}",
                style: TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                icon: Icon(Icons.assignment, color: primaryColor),
                tooltip: "History",
                onPressed: () => _openHistory(p),
              ),
            ),
          );
        },
      ),
    );
  }
}