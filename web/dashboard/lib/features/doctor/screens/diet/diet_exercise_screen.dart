import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/patient_model.dart';
import 'package:tbcare_main/features/doctor/screens/diet/components/diet_exercise_card.dart';
import 'package:tbcare_main/features/doctor/screens/diet/diet_plan_screen.dart';
import 'package:tbcare_main/features/doctor/screens/diet/exercise_plan_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

class DietExerciseScreen extends StatefulWidget {
  const DietExerciseScreen({super.key});

  @override
  State<DietExerciseScreen> createState() => _DietExerciseScreenState();
}

class _DietExerciseScreenState extends State<DietExerciseScreen> {
  late Future<List<PatientModel>> _tbPatientsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PatientModel>> _fetchTBPatients() async {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) return [];

    try {
      // 1. Fetch all patients assigned to this doctor
      final patientsSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('selectedDoctor', isEqualTo: doctorId)
          .get();

      if (patientsSnapshot.docs.isEmpty) return [];

      final List<PatientModel> confirmedTbPatients = [];

      // 2. Check each patient's LATEST screening for diagnosis status "TB"
      // doing this concurrently for performance
      await Future.wait(patientsSnapshot.docs.map((doc) async {
        final patientData = doc.data();
        final patientId = doc.id;

        // Step A: Fetch the LATEST screening (by timestamp)
        final screeningSnapshot = await doc.reference
            .collection('screenings')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (screeningSnapshot.docs.isNotEmpty) {
          final latestScreeningDoc = screeningSnapshot.docs.first;
          
          // Step B: Fetch the LATEST diagnosis for this screening (by createdAt)
          final diagnosisSnapshot = await latestScreeningDoc.reference
              .collection('diagnosis')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

          if (diagnosisSnapshot.docs.isNotEmpty) {
            final diagnosisData = diagnosisSnapshot.docs.first.data();
            
            // Step C: Only add patient if latest diagnosis status is "TB"
            if (diagnosisData['status'] == 'TB') {
              patientData['uid'] = patientId;
              confirmedTbPatients.add(PatientModel.fromMap(patientData));
            }
          }
        }
      }));

      return confirmedTbPatients;

    } catch (e) {
      debugPrint("Error fetching TB patients: $e");
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _tbPatientsFuture = _fetchTBPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Softer background
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            "Diet & Exercise",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _tbPatientsFuture = _fetchTBPatients();
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Semi-transparent white
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, size: 20, color: Colors.white),
            ),
            tooltip: "Refresh List",
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<List<PatientModel>>(
        future: _tbPatientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: errorColor.withOpacity(0.8)),
                    const SizedBox(height: 16),
                    Text(
                      "Something went wrong",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: secondaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: secondaryColor.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => setState(() => _tbPatientsFuture = _fetchTBPatients()),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Try Again"),
                      style: TextButton.styleFrom(foregroundColor: primaryColor),
                    )
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fitness_center_rounded, size: 64, color: primaryColor.withOpacity(0.4)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No Patients Found",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Patients with confirmed TB will appear here\nfor diet and exercise planning.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          var patients = snapshot.data!;
          
          if (_searchQuery.isNotEmpty) {
            patients = patients.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active Patients",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor.withOpacity(0.5),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "${snapshot.data!.length}",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "requiring plans",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: secondaryColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.assignment_turned_in_outlined, color: successColor),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search patients by name...",
                    prefixIcon: const Icon(Icons.search, color: primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
              ),

              // Patient List
              Expanded(
                child: patients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: secondaryColor.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text("No patients found", style: TextStyle(color: secondaryColor.withOpacity(0.6))),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        itemCount: patients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          return DietExerciseCard(
                            patient: patient,
                            onDietTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DietPlanScreen(patient: patient),
                                ),
                              );
                            },
                            onExerciseTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExercisePlanScreen(
                                    patientId: patient.uid,
                                    patientName: patient.name,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}