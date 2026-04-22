import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/models/screening_patient_list_model.dart';
import 'package:tbcare_main/features/chw/services/screening_patient_list_service.dart';
import 'package:tbcare_main/core/app_constants.dart';

class ScreeningHistoryScreen extends StatelessWidget {
  final Patient patient;
  final PatientService _service = PatientService();

  ScreeningHistoryScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "${patient.name}'s History",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: secondaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white, // ✅ makes the back arrow white
        ),
      ),
      body: StreamBuilder<List<Screening>>(
        stream: _service.getScreenings(patient.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text("Error loading screenings",
                    style: TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: primaryColor));
          }

          final screenings = snapshot.data!;
          if (screenings.isEmpty) {
            return const Center(
                child: Text("No screenings yet",
                    style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: screenings.length,
            itemBuilder: (context, i) {
              final s = screenings[i];
              return Card(
                color: secondaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: s.symptoms.isEmpty
                        ? [
                      const Chip(
                          label: Text('No symptoms'),
                          backgroundColor: primaryColor,
                          labelStyle:
                          TextStyle(color: Colors.white))
                    ]
                        : s.symptoms
                        .map((sym) => Chip(
                      label: Text(sym),
                      backgroundColor: primaryColor,
                      labelStyle:
                      const TextStyle(color: Colors.white),
                    ))
                        .toList(),
                  ),
                  subtitle: Text(
                      "Date: ${s.timestamp ?? 'Unknown'}\nAI: ${s.aiPrediction}\nCough: ${s.coughAudioPath.isEmpty ? 'no audio' : 'available'}",
                      style: const TextStyle(color: Colors.white70)),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
