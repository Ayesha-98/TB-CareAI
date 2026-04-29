import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/patient_model.dart';
import 'package:tbcare_main/features/doctor/services/doctor_service.dart';
import 'package:tbcare_main/features/doctor/services/patient_service.dart';
import 'package:tbcare_main/features/doctor/screens/dashboard/components/chart.dart';

class StorageDetails extends StatefulWidget {
  const StorageDetails({super.key});

  @override
  State<StorageDetails> createState() => _StorageDetailsState();
}

class _StorageDetailsState extends State<StorageDetails> {
  bool isLoading = true;
  Map<int, int> weeklyDiagnoses = {};
  Map<String, int> patientStatusCounts = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Start auto-refresh timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);
    
    try {
      final weekly = await DoctorService.fetchWeeklyDiagnoses();
      final patients = await PatientService.fetchAllPatients();

      // Process patient stats as per user request:
      // Deep dive into latest screening -> latest diagnosis status
      final stats = <String, int>{
        'TB': 0,
        'Not TB': 0,
        'Other': 0,
      };

      // Parallelize the fetching of nested statuses for each patient
      final List<Future<String?>> statusFutures = patients.map((p) async {
        try {
          // 1. Get latest screening
          final screeningSnapshot = await FirebaseFirestore.instance
              .collection('patients')
              .doc(p.uid)
              .collection('screenings')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (screeningSnapshot.docs.isEmpty) return null;
          final screeningId = screeningSnapshot.docs.first.id;

          // 2. Get latest diagnosis for that screening
          final diagnosisSnapshot = await FirebaseFirestore.instance
              .collection('patients')
              .doc(p.uid)
              .collection('screenings')
              .doc(screeningId)
              .collection('diagnosis')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

          if (diagnosisSnapshot.docs.isEmpty) {
            // If no diagnosis doc yet, fallback to screening's top-level status if it exists
            return screeningSnapshot.docs.first.data()['status']?.toString();
          }
          
          return diagnosisSnapshot.docs.first.data()['status']?.toString();
        } catch (e) {
          debugPrint("Error fetching deep status for patient ${p.uid}: $e");
          return null;
        }
      }).toList();

      final List<String?> nestedStatuses = await Future.wait(statusFutures);

      for (var status in nestedStatuses) {
        if (status == 'TB') {
          stats['TB'] = (stats['TB'] ?? 0) + 1;
        } else if (status == 'Not TB') {
          stats['Not TB'] = (stats['Not TB'] ?? 0) + 1;
        } else {
          // This includes 'Needs Lab Test', 'TB Likely', null, etc.
          stats['Other'] = (stats['Other'] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          weeklyDiagnoses = weekly;
          patientStatusCounts = stats;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading charts data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: isLoading 
        ? const SizedBox(
            height: 300, 
            child: Center(child: CircularProgressIndicator())
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chart(weeklyData: weeklyDiagnoses),
              const SizedBox(height: defaultPadding),
              
              // Patient Status Pie Chart
              Text(
                "Patient Statistics",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: defaultPadding),
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        startDegreeOffset: -90,
                        sections: _buildPieSections(),
                      ),
                    ),
                    Center(
                      child: Text(
                        "${patientStatusCounts.values.fold(0, (a, b) => a + b)}",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),
              _buildLegend(context),
            ],
          ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = patientStatusCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[200],
          value: 1,
          showTitle: false,
          radius: 25,
        ),
      ];
    }

    return [
      if ((patientStatusCounts['TB'] ?? 0) > 0)
        PieChartSectionData(
          color: errorColor, // Red
          value: (patientStatusCounts['TB'] ?? 0).toDouble(),
          title: "${patientStatusCounts['TB']}",
          radius: 25,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      if ((patientStatusCounts['Not TB'] ?? 0) > 0)
        PieChartSectionData(
          color: successColor, // Green
          value: (patientStatusCounts['Not TB'] ?? 0).toDouble(),
          title: "${patientStatusCounts['Not TB']}",
          radius: 25,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      if ((patientStatusCounts['Other'] ?? 0) > 0)
        PieChartSectionData(
          color: accentColor, // Blue
          value: (patientStatusCounts['Other'] ?? 0).toDouble(),
          title: "${patientStatusCounts['Other']}",
          radius: 25,
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
    ];
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      children: [
        _legendItem(color: errorColor, text: "Confirmed TB"),
        _legendItem(color: successColor, text: "Not TB"),
        _legendItem(color: accentColor, text: "Other Cases"),
      ],
    );
  }

  Widget _legendItem({required Color color, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: secondaryColor, fontSize: 13)),
        ],
      ),
    );
  }
}
