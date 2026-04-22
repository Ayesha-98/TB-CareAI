import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/services/chw_dashboard_service.dart';
import 'package:tbcare_main/features/chw/models/chw_dashboard_patient_model.dart';
import 'package:tbcare_main/core/app_constants.dart';

class CHWTabAllPatients extends StatelessWidget {
  final CHWDashboardService service;
  final void Function(PatientWithScreening) onPatientTap;
  final Color primaryColor;
  final Color bgColor;
  final Color secondaryColor;

  const CHWTabAllPatients({
    Key? key,
    required this.service,
    required this.onPatientTap,
    required this.primaryColor,
    required this.bgColor,
    required this.secondaryColor,
  }) : super(key: key);

  Color _getStatusColor(String? status) {
    final s = (status ?? '').toLowerCase();
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

  String _getStatusDisplayName(String? status) {
    final s = (status ?? '').toLowerCase();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: StreamBuilder<List<PatientWithScreening>>(
        stream: service.getPatientsWithScreenings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmpty("All Patients");
          }

          final patients = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final p = patients[index];
              final statusColor = _getStatusColor(p.status);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: Colors.white,
                elevation: 3,
                shadowColor: primaryColor.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () => onPatientTap(p),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Text(
                      p.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: statusColor),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '${p.age} yrs • ${p.gender}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusDisplayName(p.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String label) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 56),
          const SizedBox(height: 10),
          Text(
            'No patients in "$label"',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
