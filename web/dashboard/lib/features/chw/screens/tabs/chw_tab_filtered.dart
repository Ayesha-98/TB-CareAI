import 'package:flutter/material.dart';
import 'package:tbcare_main/features/chw/services/chw_dashboard_service.dart';
import 'package:tbcare_main/features/chw/models/chw_dashboard_patient_model.dart';

class CHWTabFiltered extends StatelessWidget {
  final CHWDashboardService service;
  final String status;
  final String title;
  final Color primaryColor;
  final Color bgColor;
  final Color secondaryColor;
  final void Function(PatientWithScreening) onPatientTap;

  const CHWTabFiltered({
    Key? key,
    required this.service,
    required this.status,
    required this.title,
    required this.primaryColor,
    required this.bgColor,
    required this.secondaryColor,
    required this.onPatientTap,
    required String searchQuery,
  }) : super(key: key);

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
            return _buildEmpty(title);
          }

          final filtered = snapshot.data!
              .where((p) => (p.status ?? '').toLowerCase() == status)
              .toList();

          if (filtered.isEmpty) return _buildEmpty(title);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final p = filtered[index];
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
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      p.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: primaryColor),
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
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: primaryColor,
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
