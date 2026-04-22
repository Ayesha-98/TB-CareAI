import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/features/chw/services/chw_dashboard_service.dart';
import 'package:tbcare_main/features/chw/models/chw_dashboard_patient_model.dart';
import 'package:tbcare_main/features/chw/models/patient_screening_model.dart';
import 'package:tbcare_main/features/chw/widgets/slide_arrow_drawer.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'tabs/chw_tab_all_patients.dart';
import 'tabs/chw_tab_filtered.dart';

class CHWDashboard extends StatefulWidget {
  const CHWDashboard({Key? key}) : super(key: key);

  @override
  State<CHWDashboard> createState() => _CHWDashboardState();
}

class _CHWDashboardState extends State<CHWDashboard> {
  final CHWDashboardService _service = CHWDashboardService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _searchQuery = '';
  int _currentIndex = 0;
  bool _isRefreshing = false;

  final List<String> _selectedPatientIds = [];
  bool _isSelectionMode = false;

  final List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(Icons.home_outlined, size: 22),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor.withOpacity(0.1),
        ),
        child: Icon(Icons.home, size: 22, color: primaryColor),
      ),
      label: 'All Patients',
    ),
    BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(Icons.medical_services_outlined, size: 22),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor.withOpacity(0.1),
        ),
        child: Icon(Icons.medical_services, size: 22, color: primaryColor),
      ),
      label: 'To Screen',
    ),
    BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(Icons.send_outlined, size: 22),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor.withOpacity(0.1),
        ),
        child: Icon(Icons.send, size: 22, color: primaryColor),
      ),
      label: 'Not Sent',
    ),
    BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(Icons.biotech_outlined, size: 22),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor.withOpacity(0.1),
        ),
        child: Icon(Icons.biotech, size: 22, color: primaryColor),
      ),
      label: 'Lab Tests',
    ),
    BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(Icons.map_outlined, size: 22),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor.withOpacity(0.1),
        ),
        child: Icon(Icons.map, size: 22, color: primaryColor),
      ),
      label: 'Maps',
    ),
  ];

  Widget _getTabScreen() {
    switch (_currentIndex) {
      case 0:
        return CHWTabAllPatients(
          service: _service,
          onPatientTap: _handlePatientTap,
          primaryColor: primaryColor,
          bgColor: bgColor,
          secondaryColor: secondaryColor,
        );

      case 1:
        return CHWTabFiltered(
          service: _service,
          status: 'not_screened',
          title: "To Screen",
          primaryColor: primaryColor,
          bgColor: bgColor,
          secondaryColor: secondaryColor,
          onPatientTap: _handlePatientTap,
        );

      case 2:
        return CHWTabFiltered(
          service: _service,
          status: 'ai_completed',
          title: "Not Sent to Doctor",
          primaryColor: primaryColor,
          bgColor: bgColor,
          secondaryColor: secondaryColor,
          onPatientTap: _handlePatientTap,
        );

      case 3:
        return CHWTabFiltered(
          service: _service,
          status: 'needs_lab_test',
          title: "Needs Lab Tests",
          primaryColor: primaryColor,
          bgColor: bgColor,
          secondaryColor: secondaryColor,
          onPatientTap: _handlePatientTap,
        );

      case 4:
        return _buildMapTab();

      default:
        return CHWTabAllPatients(
          service: _service,
          onPatientTap: _handlePatientTap,
          primaryColor: primaryColor,
          bgColor: bgColor,
          secondaryColor: secondaryColor,
        );
    }
  }

  // Dialog for lab test options
  void _showLabTestOptionsDialog(PatientWithScreening patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Patient Needs Lab Test"),
        content: const Text("This patient has been referred for lab tests. What would you like to do?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(
                context,
                AppConstants.doctorNotesRoute,
                arguments: {
                  'patientId': patient.id,
                  'screeningId': patient.latestScreening?['id'] ?? '',
                  'patientName': patient.name,
                },
              );
            },
            child: const Text("View Doctor Notes"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(
                context,
                AppConstants.labTestRoute,
                arguments: {
                  'patientId': patient.id,
                  'screeningId': patient.latestScreening?['id'] ?? '',
                  'patientName': patient.name,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Upload Lab Test"),
          ),
        ],
      ),
    );
  }

  // Navigation & tap handling
  void _handlePatientTap(PatientWithScreening patient) {
    final rawStatus = (patient.status ?? '').toString();
    final status = rawStatus.toLowerCase();

    print("🚀 Tapped patient: ${patient.name}, status: $status");

    switch (status) {
      case 'not_screened':
        Navigator.pushNamed(
          context,
          AppConstants.chwScreeningRoute,
          arguments: {
            'patientId': patient.id,
            'patientName': patient.name,
          },
        );
        break;

      case 'pending_analysis':
        _showPendingAnalysisDialog(patient);
        break;

      case 'ai_completed':
        if (patient.latestScreening != null) {
          try {
            final latest = Map<String, dynamic>.from(patient.latestScreening!);
            final docId = (latest['screeningId'] ?? latest['id'] ?? '').toString();
            if (docId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Screening id missing — cannot open AI result.')),
              );
              break;
            }

            final screeningMap = {
              ...latest,
              'id': docId,
              'screeningId': docId,
            };

            final screening = Screening.fromMap(screeningMap);
            Navigator.pushNamed(
              context,
              AppConstants.aiFlaggedRoute,
              arguments: screening,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error loading AI screening data.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No screening data available.')),
          );
        }
        break;

      case 'sent_to_doctor':
        Navigator.pushNamed(
          context,
          AppConstants.doctorNotesRoute,
          arguments: {
            'patientId': patient.id,
            'screeningId': patient.latestScreening?['id'] ?? '',
            'patientName': patient.name,
          },
        );
        break;

      case 'needs_lab_test':
        _showLabTestOptionsDialog(patient);
        break;

      case 'lab_test_uploaded':
        Navigator.pushNamed(
          context,
          AppConstants.doctorNotesRoute,
          arguments: {
            'patientId': patient.id,
            'screeningId': patient.latestScreening?['id'] ?? '',
            'patientName': patient.name,
          },
        );
        break;

      case 'completed':
        _showDoctorReviewedDialog(patient);
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown status: ${patient.status}')),
        );
    }
  }

  Widget _buildMapTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.map_rounded,
              size: 50,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Find Healthcare Facilities",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Quickly locate nearby hospitals, clinics, and healthcare centers",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              _buildMapActionButton(
                "Find TB Hospitals Nearby",
                Icons.local_hospital_rounded,
                    () => _openGoogleMaps("tb+hospitals+near+me"),
              ),
              const SizedBox(height: 12),
              _buildMapActionButton(
                "Find Health Centers",
                Icons.medical_services_rounded,
                    () => _openGoogleMaps("health+centers+near+me"),
              ),
              const SizedBox(height: 12),
              _buildMapActionButton(
                "Find Clinics",
                Icons.health_and_safety_rounded,
                    () => _openGoogleMaps("clinics+near+me"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPendingAnalysisDialog(PatientWithScreening patient) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI result pending'),
        content: const Text('AI analysis is still running for this screening.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Wait')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppConstants.chwScreeningRoute, arguments: {
                'patientId': patient.id,
                'patientName': patient.name,
              });
            },
            child: const Text('Open Screening'),
          ),
        ],
      ),
    );
  }

  void _showDoctorReviewedDialog(PatientWithScreening patient) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Doctor reviewed'),
        content: const Text('Doctor has reviewed this case.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppConstants.doctorProfileRoute, arguments: {
                'patientId': patient.id,
                'patientName': patient.name,
                'screeningId': patient.latestScreening?['screeningId'],
              });
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: primaryColor,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: primaryColor.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          // Get user data for audit log
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final userData = userDoc.data();

          // ✅ Add logout to admin audit log
          await FirebaseFirestore.instance.collection('admin_audit_logs').add({
            'action': 'LOGOUT',
            'actor': {
              'id': user.uid,
              'name': userData?['name'] ?? user.displayName ?? user.email?.split('@')[0] ?? 'Unknown',
              'email': user.email ?? '',
              'role': userData?['role'] ?? 'CHW',
            },
            'details': 'CHW logged out',
            'timestamp': FieldValue.serverTimestamp(),
            'date': DateTime.now().toIso8601String().split('T')[0],
          });
        }

        await _auth.signOut();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppConstants.signinRoute,
              (route) => false,
        );
      } catch (e) {
        print('❌ Logout error: $e');
        // Still try to sign out even if audit log fails
        await _auth.signOut();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppConstants.signinRoute,
              (route) => false,
        );
      }
    }
  }
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => _isRefreshing = false);
  }

  Future<void> _openGoogleMaps(String query) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  void _togglePatientSelection(String patientId) {
    setState(() {
      if (_selectedPatientIds.contains(patientId)) {
        _selectedPatientIds.remove(patientId);
      } else {
        _selectedPatientIds.add(patientId);
      }
      _isSelectionMode = _selectedPatientIds.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPatientIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedPatients() async {
    if (_selectedPatientIds.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patients'),
        content: Text('Delete ${_selectedPatientIds.length} selected patient(s)? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _service.deleteMultiplePatients(List<String>.from(_selectedPatientIds));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_selectedPatientIds.length} patient(s) deleted'),
          backgroundColor: Colors.green,
        ));
        _clearSelection();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete patients: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Color _getStatusColor(String status) {
    final s = (status ?? '').toLowerCase();
    switch (s) {
      case 'not_screened': return Colors.grey;
      case 'pending_analysis': return Colors.blueGrey;
      case 'ai_completed': return Colors.blue;
      case 'sent_to_doctor': return Colors.orange;
      case 'needs_lab_test': return Colors.teal;
      case 'lab_test_uploaded': return Colors.pinkAccent;
      case 'doctor_reviewed': return Colors.purple;
      case 'completed': return successColor;
      default: return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    final s = (status ?? '').toLowerCase();
    switch (s) {
      case 'not_screened': return 'Not Screened';
      case 'pending_analysis': return 'AI Pending';
      case 'ai_completed': return 'AI Done';
      case 'sent_to_doctor': return 'With Doctor';
      case 'needs_lab_test': return 'Needs Lab Test';
      case 'lab_test_uploaded': return 'Lab Test Uploaded';
      case 'doctor_reviewed': return 'Reviewed';
      case 'completed': return 'Completed';
      default: return status ?? '';
    }
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.9), primaryColor.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome!",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Community Health Worker",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Refresh Button
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: IconButton(
                      onPressed: _refreshData,
                      icon: _isRefreshing
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      tooltip: 'Refresh',
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  // Logout Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      tooltip: 'Logout',
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: "Search patients...",
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 4),
              child: Icon(Icons.search_rounded, color: primaryColor, size: 22),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear_rounded, color: Colors.grey.shade500, size: 18),
              onPressed: () => setState(() => _searchQuery = ''),
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          cursorColor: primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _isSelectionMode
          ? AppBar(
        title: Text('${_selectedPatientIds.length} selected'),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteSelectedPatients,
          ),
        ],
      )
          : null,
      body: SlideArrowDrawer( // 🔥 Wrap with slide arrow drawer
        child: Column(
          children: [
            if (!_isSelectionMode) _buildHeaderSection(),
            if (!_isSelectionMode && _currentIndex != 4) _buildSearchSection(),
            Expanded(child: _getTabScreen()),
          ],
        ),
      ),
      floatingActionButton: !_isSelectionMode && _currentIndex != 4
          ? FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => Navigator.pushNamed(context, AppConstants.managePatientsRoute),
        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
        elevation: 3,
      )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              if (_isSelectionMode) _clearSelection();
              setState(() => _currentIndex = i);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade500,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: _bottomNavItems,
          ),
        ),
      ),
    );
  }
}

// Search delegate
class _PatientSearchDelegate extends SearchDelegate<String> {
  final CHWDashboardService service;
  _PatientSearchDelegate(this.service);

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) => _buildResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults();

  Widget _buildResults() {
    return StreamBuilder<List<PatientWithScreening>>(
      stream: service.getPatientsWithScreenings(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final results = snap.data!.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
        if (results.isEmpty) return const Center(child: Text('No patients found'));
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, i) {
            final p = results[i];
            return ListTile(
              title: Text(p.name),
              subtitle: Text('${p.age} yrs • ${p.gender}'),
              trailing: Text((p.status ?? '').toString()),
              onTap: () => close(context, p.name),
            );
          },
        );
      },
    );
  }
}