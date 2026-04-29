import 'dart:async'; // 🔔 Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart'; // 🔔 Added for deep map comparison
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/patient/widgets/slide_arrow_drawer.dart';
import 'package:tbcare_main/features/patient/notification_service.dart'; // 🔔 Import notification service

// 🎨 Color Scheme
const primaryColor = Color(0xFF1B4D3E); // Dark teal
const secondaryColor = Color(0xFF2E7D32); // Green
const accentColor = Color(0xFF81C784); // Light green
const bgColor = Color(0xFFF8FDF9); // Soft green tint
const textColor = Color(0xFF333333);
const lightTextColor = Color(0xFF666666);

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final NotificationService _notificationService = NotificationService();

  String patientName = "Patient";
  List<Map<String, dynamic>> screenings = [];
  bool isLoading = true;
  String? _patientId;

  // 🔔 Notification Logic Variables
  StreamSubscription? _screeningSubscription;
  Map<String, dynamic>? _lastScreeningData;

  // Chart data
  List<BarChartGroupData> monthlyChartData = [];
  Map<String, int> screeningMonths = {};

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    _screeningSubscription?.cancel(); // 🔔 Stop listening when screen is closed
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() {
      _patientId = user.uid;
      patientName = user.displayName ?? "Patient";
    });

    await fetchScreenings();
    _initRealtimeListener(); // 🔔 Start listening for screening updates
  }

  // ================= 🔔 NOTIFICATION ENGINE WITH SAVING =================
  void _initRealtimeListener() {
    if (_patientId == null) return;

    _screeningSubscription = FirebaseFirestore.instance
        .collection('patients')
        .doc(_patientId)
        .collection('screenings')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final newData = snapshot.docs.first.data();
        final screeningId = snapshot.docs.first.id;

        if (_lastScreeningData != null) {
          // 🔔 DEEP COMPARE: Check if ANY field in the document has changed
          final eq = const DeepCollectionEquality().equals;
          if (!eq(newData, _lastScreeningData)) {
            String title = "Health Tracking Update";
            String body = "Your health record has been updated.";
            String type = "general";

            // Determine the specific message to show
            if (newData['doctorDiagnosis'] != _lastScreeningData!['doctorDiagnosis']) {
              title = "Doctor's Diagnosis Updated";
              body = "Doctor diagnosed: ${newData['doctorDiagnosis']}";
              type = "diagnosis";
            } else if (newData['aiPrediction'] != _lastScreeningData!['aiPrediction']) {
              title = "New AI Analysis Result";
              body = "AI Prediction: ${newData['aiPrediction']}";
              type = "ai_result";
            } else if (newData['status'] != _lastScreeningData!['status']) {
              title = "Status Updated";
              body = "Screening status changed to: ${newData['status']}";
              type = "status";
            } else if (newData['recommendations'] != _lastScreeningData!['recommendations']) {
              title = "New Recommendations";
              body = "Doctor added new recommendations for you";
              type = "recommendation";
            }

            // 🔔 Show popup notification
            _showNotificationPopup(title, body);

            // 💾 SAVE NOTIFICATION TO FIRESTORE
            await _notificationService.saveNotification(
              title: title,
              body: body,
              type: type,
              screeningId: screeningId,
            );
          }
        }
        _lastScreeningData = newData;
      }
    });
  }

  void _showNotificationPopup(String title, String body) {
    // Show a Material banner/snackbar notification (web-friendly)
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(body),
          ],
        ),
        backgroundColor: primaryColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              goToNotifications();
            },
            child: const Text("VIEW", style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
          ),
        ],
      ),
    );
  }

  // ================= NAVIGATION METHODS =================
  void startScreening() => Navigator.pushNamed(context, AppConstants.patientScreeningRoute);
  void goToProfile() => Navigator.pushNamed(context, AppConstants.patientProfileRoute);
  void goToHealthTips() => Navigator.pushNamed(context, AppConstants.patientHealthTipsRoute);
  void goToEducationContent() => Navigator.pushNamed(context, AppConstants.patientEducationRoute);
  void goToDietRecommendation() => Navigator.pushNamed(context, AppConstants.patientDietRecommendationRoute);
  void goToChatBot() => Navigator.pushNamed(context, AppConstants.patientChatBotRoute);
  void goToExerciseScreen() => Navigator.pushNamed(context, AppConstants.patientExerciseTrackingRoute);
  void goToNearbyHospitals() => Navigator.pushNamed(context, AppConstants.patientNearbyHospitalsRoute);
  void goToTestReports() => Navigator.pushNamed(context, AppConstants.patientTestReports);
  void goToNotifications() => Navigator.pushNamed(context, AppConstants.patientNotificationsRoute);

  // ================= LOGOUT METHOD WITH AUDIT LOG =================
  Future<void> _handleLogout() async {
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
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Get user data for audit log
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final userData = userDoc.data();

          // ✅ Add logout to audit log
          await FirebaseFirestore.instance.collection('admin_audit_logs').add({
            'action': 'LOGOUT',
            'actor': {
              'id': user.uid,
              'name': userData?['name'] ?? user.displayName ?? user.email ?? 'Unknown',
              'email': user.email ?? '',
              'role': userData?['role'] ?? 'Patient',
            },
            'details': 'Patient logged out',
            'timestamp': FieldValue.serverTimestamp(),
            'date': DateTime.now().toIso8601String().split('T')[0],
          });
        }

        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/signin',
                (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ================= DATA FETCHING =================
  Future<void> fetchScreenings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .collection('screenings')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> fetchedScreenings = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'result': data['aiPrediction'] ?? data['doctorDiagnosis'] ?? 'Pending',
          'status': data['status'] ?? 'pending',
          'timestamp': data['timestamp'],
          'doctorName': data['assignedDoctorName'] ?? 'Dr. Unknown',
          'symptoms': (data['symptoms'] as List<dynamic>?)?.join(", ") ?? 'No symptoms reported',
          'testReferred': data['testReferred'] ?? 'No test referred',
          'aiConfidence': data['aiConfidence'] ?? 'N/A',
          'recommendations': data['recommendations'] ?? 'No recommendations',
          'doctorDiagnosis': data['doctorDiagnosis'] ?? 'Pending diagnosis',
        };
      }).toList();

      _prepareChartData(fetchedScreenings);

      setState(() {
        screenings = fetchedScreenings;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading screenings: $e");
      setState(() => isLoading = false);
    }
  }

  void _prepareChartData(List<Map<String, dynamic>> screeningsList) {
    screeningMonths = {};
    monthlyChartData = [];

    for (var screening in screeningsList) {
      final Timestamp? timestamp = screening['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final DateTime date = timestamp.toDate();
        final String monthKey = "${date.year}-${date.month}";
        screeningMonths[monthKey] = (screeningMonths[monthKey] ?? 0) + 1;
      }
    }

    final List<String> last6Months = _getLast6Months();
    for (int i = 0; i < last6Months.length; i++) {
      final monthKey = last6Months[i];
      final count = screeningMonths[monthKey] ?? 0;

      monthlyChartData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: primaryColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
  }

  List<String> _getLast6Months() {
    final List<String> months = [];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      months.add("${date.year}-${date.month}");
    }
    return months;
  }

  String _getMonthName(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return "Jan";
    final month = int.tryParse(parts[1]) ?? 1;
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return monthNames[month - 1];
  }

  // ================= UI HELPERS =================
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String formatFullDate(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'negative':
        return Colors.green;
      case 'pending':
      case 'under_review':
        return Colors.orange;
      case 'positive':
      case 'critical':
        return Colors.red;
      case 'referred':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending Review';
      case 'positive':
        return 'Positive';
      case 'negative':
        return 'Negative';
      case 'under_review':
        return 'Under Review';
      case 'referred':
        return 'Referred';
      case 'critical':
        return 'Critical';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'negative':
        return Icons.check_circle_rounded;
      case 'pending':
      case 'under_review':
        return Icons.access_time_rounded;
      case 'positive':
      case 'critical':
        return Icons.warning_rounded;
      case 'referred':
        return Icons.local_hospital_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  void openSessionDetails(Map<String, dynamic> screening) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📋 Screening Details', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailSection("🩺 AI ASSESSMENT", [
                _detailRow("Prediction", screening['result']),
                _detailRow("Confidence", "${screening['aiConfidence'] ?? 'N/A'}"),
                _detailRow("Status", _getStatusText(screening['status'].toString())),
              ]),
              const SizedBox(height: 16),
              _detailSection("👨‍⚕️ DOCTOR REVIEW", [
                _detailRow("Doctor", screening['doctorName']),
                _detailRow("Diagnosis", screening['doctorDiagnosis']),
                _detailRow("Test Referred", screening['testReferred']),
                _detailRow("Recommendations", screening['recommendations']),
              ]),
              const SizedBox(height: 16),
              _detailSection("🤒 SYMPTOMS REPORTED", [
                _detailRow("Symptoms", screening['symptoms']),
              ]),
              const SizedBox(height: 16),
              _detailSection("📅 SESSION INFO", [
                _detailRow("Screening ID", screening['id'].toString().substring(0, 8)),
                _detailRow("Date & Time", formatFullDate(screening['timestamp'])),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600, color: textColor))),
          Expanded(flex: 3, child: Text(value?.toString() ?? 'N/A', style: TextStyle(color: value == null || value == 'N/A' ? Colors.grey : textColor))),
        ],
      ),
    );
  }

  // ================= UI BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/logo light.png", height: 35, width: 35),
            const SizedBox(width: 10),
            const Text("TB Care", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        backgroundColor: primaryColor,
        elevation: 4,
        centerTitle: true,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          // 🔔 NOTIFICATION BELL WITH UNREAD BADGE
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: goToNotifications,
                    tooltip: 'Notifications',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SlideArrowDrawer(
        child: Container(
          color: bgColor,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildScreeningChart(),
                            const SizedBox(height: 20),
                            _buildRecentScreenings(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: _buildQuickActions(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: primaryColor.withOpacity(0.1),
          child: const Icon(Icons.person, size: 32, color: primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome back,", style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.8))),
              Text(patientName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: startScreening,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text("New Screening"),
        ),
      ],
    );
  }

  Widget _buildScreeningChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Screening History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              if (screenings.isNotEmpty)
                Text("Total: ${screenings.length}", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          if (monthlyChartData.isNotEmpty)
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final last6Months = _getLast6Months();
                          if (value.toInt() < last6Months.length) {
                            return Text(_getMonthName(last6Months[value.toInt()]), style: TextStyle(color: Colors.grey.shade600, fontSize: 11));
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: monthlyChartData,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(screenings.isEmpty ? "No screening data yet" : "Loading chart...", style: TextStyle(color: Colors.grey.shade600)),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentScreenings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recent Screenings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              if (screenings.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  child: Text("View All (${screenings.length})", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (screenings.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.medical_services_rounded, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No screenings yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: startScreening,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    child: const Text("Start Your First Screening", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )
          else
            Column(
              children: screenings.take(5).map((screening) {
                final timestamp = screening['timestamp'] as Timestamp?;
                final date = timestamp != null ? formatTimestamp(timestamp) : "N/A";

                return GestureDetector(
                  onTap: () => openSessionDetails(screening),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: _getStatusColor(screening['status'].toString()).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getStatusColor(screening['status'].toString()).withOpacity(0.3), width: 2),
                          ),
                          child: Icon(_getStatusIcon(screening['status'].toString()), color: _getStatusColor(screening['status'].toString()), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(screening['doctorName'].toString(), style: TextStyle(fontWeight: FontWeight.w700, color: textColor, fontSize: 16)),
                                  Text(date, style: TextStyle(fontSize: 12, color: lightTextColor, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text("Result: ${screening['result']}", style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                screening['symptoms'].toString().length > 80 ? "${screening['symptoms'].toString().substring(0, 80)}..." : screening['symptoms'].toString(),
                                style: TextStyle(fontSize: 13, color: lightTextColor),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(screening['status'].toString()).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(_getStatusText(screening['status'].toString()), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _getStatusColor(screening['status'].toString()))),
                                  ),
                                  if (screening['aiConfidence'] != 'N/A') ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.timeline, size: 12, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text("${screening['aiConfidence']}%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => openSessionDetails(screening),
                          icon: Icon(Icons.chevron_right_rounded, color: primaryColor, size: 28),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildQuickActionItem(icon: Icons.medical_services_rounded, label: "Start Screening", onTap: startScreening, color: primaryColor),
              _buildQuickActionItem(icon: Icons.person_rounded, label: "My Profile", onTap: goToProfile, color: Colors.blue),
              _buildQuickActionItem(icon: Icons.health_and_safety_rounded, label: "Health Tips", onTap: goToHealthTips, color: Colors.green),
              _buildQuickActionItem(icon: Icons.menu_book_rounded, label: "Education", onTap: goToEducationContent, color: Colors.purple),
              _buildQuickActionItem(icon: Icons.restaurant_rounded, label: "Diet Plan", onTap: goToDietRecommendation, color: Colors.orange),
              _buildQuickActionItem(icon: Icons.fitness_center_rounded, label: "Exercise", onTap: goToExerciseScreen, color: Colors.red),
              _buildQuickActionItem(icon: Icons.local_hospital_rounded, label: "Nearby Hospitals", onTap: goToNearbyHospitals, color: Colors.teal),
              _buildQuickActionItem(icon: Icons.assignment_rounded, label: "Test Reports", onTap: goToTestReports, color: Colors.purple.shade400),
              _buildQuickActionItem(icon: Icons.chat_rounded, label: "Chat with Assistant", onTap: goToChatBot, color: Colors.indigo),
              // 🔔 ADD NOTIFICATIONS BUTTON
              _buildQuickActionItem(icon: Icons.notifications_rounded, label: "My Notifications", onTap: goToNotifications, color: Colors.amber.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}