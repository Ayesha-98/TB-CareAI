import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';

class QuickStatsWidget extends StatelessWidget {
  final int confirmedTBCount;
  final int totalPatientsReviewed;
  final int totalDiagnosisMade;

  const QuickStatsWidget({
    super.key,
    required this.confirmedTBCount,
    required this.totalPatientsReviewed,
    required this.totalDiagnosisMade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'TB Cases\nConfirmed',
                confirmedTBCount.toString(),
                Icons.coronavirus,
                errorColor,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'Patients\nReviewed',
                totalPatientsReviewed.toString(),
                Icons.people,
                successColor,
              ),
            ),
            _buildDivider(),
            Expanded(
              child: _buildStatItem(
                'Diagnoses\nMade',
                totalDiagnosisMade.toString(),
                Icons.assignment_turned_in,
                primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: smallPadding),
        Text(
          value,
          style: const TextStyle(
            color: secondaryColor,
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryColor.withOpacity(0.7),
            fontSize: captionSize,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 1,
      color: secondaryColor.withOpacity(0.15),
      margin: const EdgeInsets.symmetric(horizontal: defaultPadding),
    );
  }
}