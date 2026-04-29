import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

// 🎨 Modern Dashboard Color Scheme
const primaryColor = Color(0xFF4361EE); // Vibrant Blue
const secondaryColor = Color(0xFF3A0CA3); // Deep Purple
const accentColor = Color(0xFF4CC9F0); // Light Blue
const successColor = Color(0xFF4CAF50); // Green
const warningColor = Color(0xFFFF9800); // Orange
const errorColor = Color(0xFFF44336); // Red
const backgroundColor = Color(0xFFF8F9FF); // Light Blue Background
const cardColor = Colors.white;
const textPrimary = Color(0xFF2D3748);
const textSecondary = Color(0xFF718096);
const borderColor = Color(0xFFE2E8F0);

class EnhancedFitnessDashboard extends StatefulWidget {
  const EnhancedFitnessDashboard({super.key});

  @override
  State<EnhancedFitnessDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<EnhancedFitnessDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dashboard Data
  Map<String, dynamic>? _patientProfile;
  Map<String, dynamic>? _todayHealthData;
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _medicationSchedule = [];
  List<Map<String, dynamic>> _healthStats = [];

  bool _isLoading = true;
  bool _refreshing = false;

  // Health Metrics
  int _todaySteps = 0;
  int _dailyGoalSteps = 10000;
  int _heartRate = 72;
  double _temperature = 36.6;
  int _oxygenSaturation = 98;
  int _bloodPressureSys = 120;
  int _bloodPressureDia = 80;

  // Charts Data
  List<double> _weeklyHeartRate = [];
  List<double> _weeklyTemperature = [];
  List<double> _weeklySteps = [];

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      await Future.wait([
        _loadPatientProfile(),
        _loadTodayHealthData(),
        _loadRecentActivities(),
        _loadUpcomingAppointments(),
        _loadMedicationSchedule(),
        _loadHealthStats(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPatientProfile() async {
    try {
      if (user == null) return;

      final doc = await _firestore.collection('patients').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          _patientProfile = doc.data();
        });
      }
    } catch (e) {
      debugPrint('Error loading patient profile: $e');
    }
  }

  Future<void> _loadTodayHealthData() async {
    try {
      if (user == null) return;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final doc = await _firestore
          .collection('patients')
          .doc(user!.uid)
          .collection('health_metrics')
          .doc(today)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _todayHealthData = data;
          _todaySteps = data['steps'] ?? 0;
          _heartRate = data['heartRate'] ?? 72;
          _temperature = data['temperature'] ?? 36.6;
          _oxygenSaturation = data['oxygenSaturation'] ?? 98;
        });
      }
    } catch (e) {
      debugPrint('Error loading today health data: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      if (user == null) return;

      final query = await _firestore
          .collection('patients')
          .doc(user!.uid)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      setState(() {
        _recentActivities = query.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading recent activities: $e');
    }
  }

  Future<void> _loadUpcomingAppointments() async {
    try {
      if (user == null) return;

      final now = Timestamp.now();
      final query = await _firestore
          .collection('patients')
          .doc(user!.uid)
          .collection('appointments')
          .where('dateTime', isGreaterThanOrEqualTo: now)
          .orderBy('dateTime')
          .limit(3)
          .get();

      setState(() {
        _upcomingAppointments = query.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading upcoming appointments: $e');
    }
  }

  Future<void> _loadMedicationSchedule() async {
    try {
      if (user == null) return;

      final query = await _firestore
          .collection('patients')
          .doc(user!.uid)
          .collection('medications')
          .where('active', isEqualTo: true)
          .get();

      setState(() {
        _medicationSchedule = query.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading medication schedule: $e');
    }
  }

// Update the health stats loading function
  Future<void> _loadHealthStats() async {
    try {
      if (user == null) return;

      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final query = await _firestore
          .collection('patients')
          .doc(user!.uid)
          .collection('health_metrics')
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(weekAgo))
          .orderBy('date')
          .get();

      setState(() {
        _healthStats = query.docs.map((doc) => doc.data()).toList();

        // Prepare chart data with proper type conversion
        _weeklyHeartRate = _healthStats
            .where((data) => data['heartRate'] != null)
            .map((data) => (data['heartRate'] as num).toDouble())
            .toList();

        _weeklyTemperature = _healthStats
            .where((data) => data['temperature'] != null)
            .map((data) => (data['temperature'] as num).toDouble())
            .toList();

        _weeklySteps = _healthStats
            .where((data) => data['steps'] != null)
            .map((data) => (data['steps'] as num).toDouble())
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading health stats: $e');
    }
  }

// Also fix the metric card trend calculation
  String? _calculateTrend(List<double> data) {
    if (data.length < 2) return null;

    final last = data.last;
    final previous = data[data.length - 2];
    final change = last - previous;

    if (change == 0) return null;

    return '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}';
  }

  Future<void> _manualRefresh() async {
    if (_refreshing) return;

    setState(() => _refreshing = true);
    try {
      await _initializeDashboard();
    } catch (e) {
      debugPrint('❌ Error refreshing: $e');
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Widget _buildWebDashboard() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Patient Dashboard",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Welcome back, ${_patientProfile?['name']?.split(' ').first ?? 'Patient'}",
                      style: TextStyle(
                        fontSize: 18,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Status: ${_patientProfile?['status'] ?? 'Active'}",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _manualRefresh,
                      icon: Icon(
                        Icons.refresh,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Health Metrics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _buildMetricCard(
                  title: "Heart Rate",
                  value: "$_heartRate",
                  unit: "BPM",
                  icon: Iconsax.heart,
                  color: errorColor,
                  trend: _calculateTrend(_weeklyHeartRate),
                ),
                _buildMetricCard(
                  title: "Temperature",
                  value: "$_temperature",
                  unit: "°C",
                  icon: Iconsax.sun,
                  color: warningColor,
                  trend: _calculateTrend(_weeklyTemperature),
                ),
                _buildMetricCard(
                  title: "Oxygen Saturation",
                  value: "$_oxygenSaturation",
                  unit: "%",
                  icon: Iconsax.wind,
                  color: successColor,
                ),
                _buildMetricCard(
                  title: "Daily Steps",
                  value: "$_todaySteps",
                  unit: "steps",
                  icon: Iconsax.activity,
                  color: primaryColor,
                  progress: _todaySteps / _dailyGoalSteps,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Health Trends Chart
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: borderColor, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Health Trends",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Last 7 days",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: _buildTrendChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Appointments & Medications
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Upcoming Appointments
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: borderColor, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Iconsax.calendar_2, color: primaryColor, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Upcoming Appointments",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (_upcomingAppointments.isEmpty)
                                _buildEmptyState("No upcoming appointments", Iconsax.calendar)
                              else
                                ..._upcomingAppointments.map((appointment) {
                                  return _buildAppointmentItem(appointment);
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Medication Schedule
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: borderColor, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Iconsax.health, color: primaryColor, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Medication Schedule",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (_medicationSchedule.isEmpty)
                                _buildEmptyState("No medications scheduled", Iconsax.health)
                              else
                                ..._medicationSchedule.take(3).map((medication) {
                                  return _buildMedicationItem(medication);
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Activities & Quick Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent Activities
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: borderColor, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Iconsax.activity, color: primaryColor, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                "Recent Activities",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_recentActivities.isEmpty)
                            _buildEmptyState("No recent activities", Iconsax.activity)
                          else
                            ..._recentActivities.map((activity) {
                              return _buildActivityItem(activity);
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Quick Actions
                Expanded(
                  flex: 1,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: borderColor, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Quick Actions",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildQuickActionButton(
                            icon: Iconsax.add_square,
                            label: "Log Health Data",
                            color: primaryColor,
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActionButton(
                            icon: Iconsax.calendar_add,
                            label: "Book Appointment",
                            color: successColor,
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActionButton(
                            icon: Iconsax.message,
                            label: "Message Doctor",
                            color: secondaryColor,
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActionButton(
                            icon: Iconsax.document,
                            label: "View Reports",
                            color: warningColor,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    double? progress,
    String? trend,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trend.contains('+') ? successColor.withOpacity(0.1) : errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          trend.contains('+') ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                          size: 12,
                          color: trend.contains('+') ? successColor : errorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: trend.contains('+') ? successColor : errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                if (progress != null)
                  SizedBox(
                    width: 80,
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: borderColor,
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 4,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _HealthChartPainter(
        heartRateData: _weeklyHeartRate,
        temperatureData: _weeklyTemperature,
        stepsData: _weeklySteps,
      ),
    );
  }

  Widget _buildAppointmentItem(Map<String, dynamic> appointment) {
    final dateTime = (appointment['dateTime'] as Timestamp).toDate();
    final formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
    final formattedTime = DateFormat('h:mm a').format(dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                formattedDate.split(' ')[1],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['doctorName'] ?? 'Doctor',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  appointment['type'] ?? 'Checkup',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                appointment['status'] ?? 'Scheduled',
                style: TextStyle(
                  fontSize: 12,
                  color: appointment['status'] == 'Confirmed' ? successColor : warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(Map<String, dynamic> medication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: successColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Iconsax.health, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication['name'] ?? 'Medication',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${medication['dosage'] ?? ''} • ${medication['frequency'] ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            medication['takenToday'] == true ? Iconsax.tick_circle : Iconsax.close_circle,
            color: medication['takenToday'] == true ? successColor : errorColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getActivityColor(activity['type']),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _getActivityIcon(activity['type']),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Activity',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  activity['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(activity['timestamp']),
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Icon(Iconsax.arrow_right_3, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 20),
          Text(
            'Loading your dashboard...',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'exercise':
        return successColor;
      case 'medication':
        return primaryColor;
      case 'appointment':
        return secondaryColor;
      case 'measurement':
        return warningColor;
      default:
        return textSecondary;
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'exercise':
        return Iconsax.activity;
      case 'medication':
        return Iconsax.health;
      case 'appointment':
        return Iconsax.calendar;
      case 'measurement':
        return Iconsax.chart;
      default:
        return Iconsax.info_circle;
    }
  }

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime time;
    if (timestamp is Timestamp) {
      time = timestamp.toDate();
    } else if (timestamp is String) {
      time = DateTime.parse(timestamp);
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWebDashboard() : _buildMobileDashboard();
  }

  Widget _buildMobileDashboard() {
    // Implement mobile layout similar to web but optimized for mobile
    // You can adapt the web layout for mobile with a single column
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _manualRefresh,
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingScreen() : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Add mobile version components here
            // Similar structure to web but single column
          ],
        ),
      ),
    );
  }
}

class _HealthChartPainter extends CustomPainter {
  final List<double> heartRateData;
  final List<double> temperatureData;
  final List<double> stepsData;

  _HealthChartPainter({
    required this.heartRateData,
    required this.temperatureData,
    required this.stepsData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 20.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw heart rate line
    if (heartRateData.isNotEmpty) {
      final heartRatePaint = Paint()
        ..color = errorColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      _drawLine(canvas, heartRateData, chartWidth, chartHeight, padding, heartRatePaint);
    }

    // Draw temperature line
    if (temperatureData.isNotEmpty) {
      final temperaturePaint = Paint()
        ..color = warningColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      _drawLine(canvas, temperatureData, chartWidth, chartHeight, padding, temperaturePaint);
    }
  }

  void _drawLine(Canvas canvas, List<double> data, double width, double height, double padding, Paint paint) {
    final points = <Offset>[];
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = padding + (width / (data.length - 1)) * i;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = padding + height - (normalizedValue * height);
      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}