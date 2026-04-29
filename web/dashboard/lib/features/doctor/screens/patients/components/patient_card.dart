import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/screens/patients/patient_details_screen.dart';
import '../../../models/patient_model.dart';

class PatientCard extends StatelessWidget {
  final PatientModel patient;

  const PatientCard({super.key, required this.patient});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "tb":
        return errorColor;
      case "tb likely":
        return warningColor;
      case "not tb":
        return successColor;
      default:
        return accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = patient.diagnosisStatus.trim();

    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: 10,
        ),
        leading: const CircleAvatar(
          backgroundColor: primaryColor,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          patient.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: secondaryColor,
            fontSize: bodySize,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Age: ${patient.age} | Gender: ${patient.gender}',
              style: TextStyle(
                color: secondaryColor.withOpacity(0.7),
                fontSize: captionSize,
              ),
            ),
            const SizedBox(height: 8),
            if (status.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusColor(status).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: secondaryColor.withOpacity(0.5),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDetailScreen(patient: patient),
            ),
          );
        },
      ),
    );
  }
}