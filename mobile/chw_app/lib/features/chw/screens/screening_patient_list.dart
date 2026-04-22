import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/models/screening_patient_list_model.dart';
import 'package:tbcare_main/features/chw/services/screening_patient_list_service.dart';
import 'screening_history_screen.dart';
import 'package:tbcare_main/core/app_constants.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final PatientService _service = PatientService();
  bool _loading = true;
  List<Patient> _patients = [];

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
        builder: (_) => ScreeningHistoryScreen(patient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "My Patients",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: secondaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white, // ✅ makes the back arrow white
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _patients.isEmpty
          ? const Center(
        child: Text("No screened patients found",
            style: TextStyle(color: Colors.white)),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: _patients.length,
        itemBuilder: (context, i) {
          final p = _patients[i];
          return Card(
            color: secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(p.name,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text("ID: ${p.id}",
                  style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(
                icon: const Icon(Icons.assignment, color: primaryColor),
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
