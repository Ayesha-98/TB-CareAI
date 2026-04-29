import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tbcare_main/features/chw/services/chw_dashboard_service.dart';
import 'package:tbcare_main/features/chw/models/chw_dashboard_patient_model.dart';
import 'package:tbcare_main/features/chw/models/patient_screening_model.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:tbcare_main/features/chw/widgets/slide_arrow_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tabs/chw_tab_all_patients.dart';
import 'tabs/chw_tab_filtered.dart';

// Modern color scheme
const primaryColor = Color(0xFF1B4D3E);
const secondaryColor = Color(0xFF2E7D32);
const accentColor = Color(0xFF81C784);
const bgColor = Color(0xFFF8FDF9);
const textColor = Color(0xFF333333);
const lightTextColor = Color(0xFF666666);
const cardColor = Color(0xFFFFFFFF);
const successColor = Color(0xFF4CAF50);
const warningColor = Color(0xFFFF9800);
const infoColor = Color(0xFF2196F3);
const errorColor = Color(0xFFF44336);

class CHWDashboard extends StatefulWidget {
  const CHWDashboard({Key? key}) : super(key: key);

  @override
  State<CHWDashboard> createState() => _CHWDashboardState();
}

class _CHWDashboardState extends State<CHWDashboard> with SingleTickerProviderStateMixin {
  final CHWDashboardService _service = CHWDashboardService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _searchQuery = '';
  int _currentIndex = 0;
  bool _isRefreshing = false;
  late TabController _tabController;

  List<PatientWithScreening> _allPatients = [];
  bool _loadingPatients = true;
  String _chwName = "Community Health Worker";
  String _greeting = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPatients();
    _loadCHWName();
    _updateGreeting();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = "Good Morning";
      } else if (hour < 17) {
        _greeting = "Good Afternoon";
      } else {
        _greeting = "Good Evening";
      }
    });
  }

  Future<void> _loadCHWName() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _chwName = user.displayName ?? "Community Health Worker";
        });
      }
    } catch (e) {
      print('Error loading CHW name: $e');
    }
  }

  Future<void> _loadPatients() async {
    setState(() => _loadingPatients = true);
    try {
      final stream = _service.getPatientsWithScreenings();
      await for (final patients in stream.take(1)) {
        setState(() {
          _allPatients = patients;
          _loadingPatients = false;
        });
      }
    } catch (e) {
      print('Error loading patients: $e');
      setState(() => _loadingPatients = false);
    }
  }

  void _handlePatientTap(PatientWithScreening patient) {
    final rawStatus = (patient.status ?? '').toString();
    final status = rawStatus.toLowerCase();

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

            final screening = Screening.fromMap(screeningMap).copyWith(
              id: docId,
            );

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
        Navigator.pushNamed(
          context,
          AppConstants.labTestRoute,
          arguments: {
            'patientId': patient.id,
            'screeningId': patient.latestScreening?['id'] ?? '',
            'patientName': patient.name,
          },
        );
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

  void _showPendingAnalysisDialog(PatientWithScreening patient) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI result pending'),
        content: const Text('AI analysis is still running for this screening. You can wait or re-open the screening to re-run / review.'),
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
        content: const Text('Doctor has reviewed this case. Open doctor record for details.'),
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
    await _loadPatients();
    await Future.delayed(const Duration(milliseconds: 500));
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

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    switch (s) {
      case 'not_screened':
        return Colors.grey;
      case 'pending_analysis':
        return Colors.blueGrey;
      case 'ai_completed':
        return Colors.blue;
      case 'sent_to_doctor':
        return Colors.orange;
      case 'needs_lab_test':
        return Colors.teal;
      case 'lab_test_uploaded':
        return Colors.pinkAccent;
      case 'doctor_reviewed':
        return Colors.purple;
      case 'completed':
        return successColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    final s = status.toLowerCase();
    switch (s) {
      case 'not_screened':
        return 'Not Screened';
      case 'pending_analysis':
        return 'AI Pending';
      case 'ai_completed':
        return 'AI Done';
      case 'sent_to_doctor':
        return 'With Doctor';
      case 'needs_lab_test':
        return 'Needs Lab Test';
      case 'lab_test_uploaded':
        return 'Lab Uploaded';
      case 'doctor_reviewed':
        return 'Reviewed';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  // --- HEADER WITH PROPER MARGINS ---
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // ✅ Left & Right margin
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "TB Care",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _greeting,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _chwName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "${_allPatients.length} Total Patients",
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(DateTime.now()),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
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

  // --- SEARCH BAR WITH MARGINS ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // ✅ Left & Right margin
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: "Search patients...",
            hintStyle: TextStyle(color: lightTextColor),
            prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear_rounded, color: lightTextColor),
              onPressed: () => setState(() => _searchQuery = ''),
            )
                : null,
          ),
          style: TextStyle(color: textColor),
          cursorColor: primaryColor,
        ),
      ),
    );
  }

  // --- PATIENTS TAB SECTION WITH MARGINS ---
  Widget _buildPatientsSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20), // ✅ Left & Right margin
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: lightTextColor,
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'All Patients'),
              Tab(text: 'To Screen'),
              Tab(text: 'Not Sent'),
              Tab(text: 'Lab Tests'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20), // ✅ Left & Right margin
            child: TabBarView(
              controller: _tabController,
              children: [
                CHWTabAllPatients(
                  service: _service,
                  onPatientTap: _handlePatientTap,
                  primaryColor: primaryColor,
                  bgColor: bgColor,
                  secondaryColor: secondaryColor,
                  searchQuery: _searchQuery,
                ),
                CHWTabFiltered(
                  service: _service,
                  status: 'not_screened',
                  title: "To Screen",
                  primaryColor: primaryColor,
                  bgColor: bgColor,
                  secondaryColor: secondaryColor,
                  onPatientTap: _handlePatientTap,
                  searchQuery: _searchQuery,
                ),
                CHWTabFiltered(
                  service: _service,
                  status: 'not_sent_to_doctor',
                  title: "Not Sent to Doctor",
                  primaryColor: primaryColor,
                  bgColor: bgColor,
                  secondaryColor: secondaryColor,
                  onPatientTap: _handlePatientTap,
                  searchQuery: _searchQuery,
                ),
                CHWTabFiltered(
                  service: _service,
                  status: 'needs_lab_test',
                  title: "Needs Lab Tests",
                  primaryColor: primaryColor,
                  bgColor: bgColor,
                  secondaryColor: secondaryColor,
                  onPatientTap: _handlePatientTap,
                  searchQuery: _searchQuery,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- MAPS TAB WITH MARGINS ---
  Widget _buildMapTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // ✅ Left & Right margin
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.map_rounded, size: 50, color: primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            "Healthcare Facilities",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Find nearby hospitals, clinics, and labs",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: lightTextColor),
          ),
          const SizedBox(height: 32),
          _buildMapCard(
            "TB Hospitals",
            Icons.local_hospital_rounded,
            "Specialized TB treatment centers",
            Colors.red,
                () => _openGoogleMaps("tb+hospitals+near+me"),
          ),
          const SizedBox(height: 12),
          _buildMapCard(
            "Health Centers",
            Icons.medical_services_rounded,
            "General health facilities",
            Colors.blue,
                () => _openGoogleMaps("health+centers+near+me"),
          ),
          const SizedBox(height: 12),
          _buildMapCard(
            "Diagnostic Labs",
            Icons.science_rounded,
            "Laboratories for TB testing",
            Colors.purple,
                () => _openGoogleMaps("diagnostic+labs+near+me"),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(String title, IconData icon, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: lightTextColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SlideArrowDrawer(
        child: Column(
          children: [
            _buildHeader(),
            if (_currentIndex == 0) _buildSearchBar(),
            Expanded(
              child: _currentIndex == 0
                  ? _loadingPatients
                  ? _buildLoadingState()
                  : _buildPatientsSection()
                  : _buildMapTab(),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => Navigator.pushNamed(context, AppConstants.managePatientsRoute),
        child: const Icon(Icons.add_rounded, color: Colors.white),
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
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade500,
            backgroundColor: Colors.white,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Maps',
              ),
            ],
          ),
        ),
      ),
    );
  }
}