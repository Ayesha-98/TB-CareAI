import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tbcare_main/features/chw/models/followup_patient_model.dart';
import 'package:tbcare_main/features/chw/services/followup_patient_service.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/chw/screens/doctor_notes_screen.dart';

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  final _service = FollowUpService();
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final Map<String, bool> _doneStatus = {}; // track done button per patient

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Follow-ups', style: TextStyle(color: Colors.white)),
        backgroundColor: secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Screening>>(
        stream: _service.getDoctorFollowUps(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'No patients sent to doctor yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];

              // Track button disabled state
              _doneStatus.putIfAbsent(s.id, () => false);

              String date = "Unknown";
              if (s.timestamp != null) {
                try {
                  date = _dateFormat.format(s.timestamp!);
                } catch (_) {
                  date = s.timestamp.toString();
                }
              }

              return Card(
                color: secondaryColor,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.person, color: primaryColor),
                  title: Text(s.patientName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Date: $date\nAI: ${s.aiPrediction}\nStatus: ${s.followUpStatus}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorNotesScreen(
                                patientId: s.patientId,
                                screeningId: s.id,
                                patientName: s.patientName,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        onPressed: _doneStatus[s.id]!
                            ? null
                            : () async {
                          setState(() => _doneStatus[s.id] = true);
                          await _service.markCompleted(
                              s.id, s.patientId, s.patientName);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${s.patientName} marked completed')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
