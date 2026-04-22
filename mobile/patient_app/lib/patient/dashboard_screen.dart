import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:collection/collection.dart';
import 'package:tb_project/patient/widgets/slide_arrow_drawer.dart';
import 'notification_service.dart';
import 'dashboard_card.dart';

// 🎨 Updated Color Scheme
const primaryColor = Color(0xFF1B4D3E);
const secondaryColor = Color(0xFF424242);
const bgColor = Color(0xFFFFFFFF);

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String patientName = "To TB Care Application";
  bool isHovering = false;
  String? _patientId;

  // 🔔 Notification Logic Variables
  StreamSubscription? _notificationSubscription;
  Map<String, dynamic>? _lastData;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  void _loadPatientData() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _patientId = user.uid;
        patientName = user.displayName ?? "To TB Care Application";
      });
      _initRealtimeListener();
    } else {
      _auth.authStateChanges().listen((User? user) {
        if (user != null && mounted) {
          setState(() {
            _patientId = user.uid;
            patientName = user.displayName ?? "To TB Care Application";
          });
          _initRealtimeListener();
        }
      });
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // ================= 🔔 NOTIFICATION ENGINE WITH SAVING =================
  void _initRealtimeListener() {
    if (_patientId == null) return;

    _notificationSubscription = FirebaseFirestore.instance
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

        if (_lastData != null) {
          final eq = const DeepCollectionEquality().equals;
          if (!eq(newData, _lastData)) {

            String title = "Health Tracking Update";
            String body = "Your health record has been updated.";
            String type = "general";

            if (newData['doctorDiagnosis'] != _lastData!['doctorDiagnosis']) {
              title = "Doctor's Diagnosis Updated";
              body = "Doctor diagnosed: ${newData['doctorDiagnosis']}";
              type = "diagnosis";
            } else if (newData['aiPrediction'] != _lastData!['aiPrediction']) {
              title = "New AI Analysis Result";
              body = "AI Prediction: ${newData['aiPrediction']}";
              type = "ai_result";
            } else if (newData['status'] != _lastData!['status']) {
              title = "Status Updated";
              body = "Screening status changed to: ${newData['status']}";
              type = "status";
            } else if (newData['recommendations'] != _lastData!['recommendations']) {
              title = "New Recommendations";
              body = "Doctor added new recommendations for you";
              type = "recommendation";
            }

            _triggerTopNotify(title, body);

            await _notificationService.saveNotification(
              title: title,
              body: body,
              type: type,
              screeningId: screeningId,
            );
          }
        }
        _lastData = newData;
      }
    });
  }

  void _triggerTopNotify(String title, String body) {
    showSimpleNotification(
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(body),
      background: primaryColor,
      foreground: Colors.white,
      duration: const Duration(seconds: 4),
      position: NotificationPosition.top,
      leading: const Icon(Icons.notifications_active, color: Colors.white),
    );
  }

  // ================= LOGOUT METHOD =================
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
        final user = _auth.currentUser;
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

        await _auth.signOut();
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

  // ================= NAVIGATION =================
  void startScreening() => Navigator.pushNamed(context, '/screening');
  void goToProfile() => Navigator.pushNamed(context, '/profile');
  void goToHealthTips() => Navigator.pushNamed(context, '/healthtips');
  void goToEducationContent() => Navigator.pushNamed(context, '/education');
  void goToDietRecommendation() => Navigator.pushNamed(context, '/diet');
  void goToChatBot() => Navigator.pushNamed(context, '/chatbot');
  void goToExerciseScreen() => Navigator.pushNamed(context, '/exercise');
  void goToTestReports() => Navigator.pushNamed(context, '/test-reports');
  void goToNotifications() => Navigator.pushNamed(context, '/notifications');

  // ================= SESSION DETAILS =================
  void openSessionDetails(Map<String, dynamic> e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Session Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              section("🩺 AI RESULT"),
              row("Prediction", e['aiPrediction']),
              row("Confidence", "${e['aiConfidence'] ?? 'N/A'}%"),
              row("Normal Probability", e['prediction']?['normal_probability']),
              row("TB Probability", e['prediction']?['tb_probability']),

              const SizedBox(height: 10),
              section("👨‍⚕ DOCTOR"),
              row("Doctor Diagnosis", e['doctorDiagnosis']),
              row("Recommendations", e['recommendations']),
              row("Test Referred", e['testReferred']),
              row("Diagnosed By", e['diagnosedBy']),

              const SizedBox(height: 10),
              section("🤒 SYMPTOMS"),
              row("Symptoms", (e['symptoms'] as List?)?.join(", ")),

              const SizedBox(height: 10),
              section("📌 STATUS"),
              row("Status", e['status']),
              row("Session Time", formatTimestamp(e['timestamp'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: primaryColor)),
          )
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/tblogo2.png", height: 40, width: 40),
            const SizedBox(width: 10),
            const Text("TB Care"),
          ],
        ),
        backgroundColor: primaryColor,
        elevation: 6,
        centerTitle: true,
        foregroundColor: Colors.white,
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
          // 🚪 LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 4),
        ],
      ),

      // 🔥 WRAPPED WITH SLIDE ARROW DRAWER FOR NOTIFICATIONS
      body: SlideArrowDrawer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ================= HEADER =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, secondaryColor],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/logo light.png",
                        fit: BoxFit.cover,
                        height: 50,
                        width: 50,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "👋 Welcome back,",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_patientId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "ID: ${_patientId!.substring(0, 8)}...",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= DASHBOARD CARDS =================
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: "Screening",
                    icon: Icons.mic,
                    onTap: startScreening,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardCard(
                    title: "My Profile",
                    icon: Icons.person,
                    onTap: goToProfile,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: "Health Tips",
                    icon: Icons.health_and_safety,
                    onTap: goToHealthTips,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardCard(
                    title: "Education",
                    icon: Icons.menu_book,
                    onTap: goToEducationContent,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: "Diet Plan",
                    icon: Icons.food_bank,
                    onTap: goToDietRecommendation,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardCard(
                    title: "Exercise",
                    icon: Icons.fitness_center,
                    onTap: goToExerciseScreen,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Test Reports Card - Full width
            SizedBox(
              width: double.infinity,
              child: DashboardCard(
                title: "Test Reports",
                icon: Icons.assignment,
                onTap: goToTestReports,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 24),
            Text("📊 PATIENT TRACKING", style: sectionTitleStyle),
            const SizedBox(height: 8),

            // ================= REAL-TIME TRACKING =================
            _buildScreeningsStream(),

            // Add bottom padding to ensure content doesn't get cut off
            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: MouseRegion(
        onEnter: (_) => setState(() => isHovering = true),
        onExit: (_) => setState(() => isHovering = false),
        child: FloatingActionButton.extended(
          onPressed: goToChatBot,
          label: Text(isHovering ? 'Ask ChatBot' : 'ChatBot'),
          icon: const Icon(Icons.chat),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildScreeningsStream() {
    if (_patientId == null) {
      return const Center(
        child: Text(
          "Please sign in to view screenings",
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patients')
          .doc(_patientId)
          .collection('screenings')
          .orderBy('timestamp', descending: true)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error loading screenings");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            "No screenings yet. Start your first screening!",
            style: TextStyle(color: Colors.black54),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () => openSessionDetails(data),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.white),
                  title: Text(
                    "Result: ${data['aiPrediction'] ?? 'Unknown'}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Time: ${formatTimestamp(data['timestamp'])}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(data['status'] ?? 'pending'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (data['status'] ?? 'pending').toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    switch (s) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'needs lab test':
        return Colors.blue;
      case 'sent to doctor':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ================= HELPERS =================
  String formatTimestamp(Timestamp? t) {
    if (t == null) return "Unknown";
    final d = t.toDate();
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} "
        "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  Widget section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 10),
    child: Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: primaryColor)),
  );

  Widget row(String title, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text("$title: ${value ?? 'N/A'}",
        style: const TextStyle(color: Colors.black87)),
  );

  TextStyle get sectionTitleStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    letterSpacing: 0.8,
  );
}